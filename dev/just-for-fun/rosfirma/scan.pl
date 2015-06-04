use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use threads;

use DBI;
use WWW::Mechanize;
# http://www.rosfirm.ru/catalog/

our $category_limit = 15; # there will be maximum xx threads reading categories

our $type_categories = 1;
our $type_companies  = 2;

our $status_ready = 0;
our $status_processing = 1;
our $status_done = 2;

# begin work


my $dbh = get_dbh();

check_first_start($dbh);


# start all possible workers first
my $rows = get_opened_categories($dbh, $category_limit);
foreach my $row (@$rows){
	my $xx = threads->create( 'category_worker', $row->{ID}, $row->{URL} );
}


do {
	
	# get joinable threads
	my @joinable_list = threads->list(threads::joinable);
	my $jcount = @joinable_list;
	# join and save data
	foreach my $thread (@joinable_list){
		my $data = $thread->join();
		my $cat_id = $data->{ID};
		my $type = $data->{type};
		my $next_page = $data->{next_page};
		my $subdata = $data->{data};
		
		if ($type==$type_categories){
			insert_categories($cat_id, $subdata);
		} else {
			insert_companies($cat_id, $next_page, $subdata);
		}
		$dbh->commit;
	}	
	print "Joined $jcount threads\n" if $jcount;

	if($jcount){
		$rows = get_opened_categories($dbh, $jcount);
		foreach my $row (@$rows){
			my $xx = threads->create( 'category_worker', $row->{ID}, $row->{URL} );
		}
	}
	
} while (threads->list() > 0);





##################################### WORKERS #############################################

sub category_worker {
	my ($category_id, $url) = @_;
	
	my @data;
	my $next_page = '';
	
	my $content = pretty_content( safe_get($url) );
	my $type = check_content_type($content);
	
	if ($type==$type_categories){
		get_categories($content, \@data);
	} else {
		get_companies($content, \@data);
		# there might be more than one page
		$next_page = get_next_page($content);
	}
	
	return {
		ID => $category_id,
		type => $type,
		data => \@data,
		next_page => $next_page
	};
}


##################################### PARSERS #############################################

sub get_next_page {
	my $content = shift;
	my $np = '';
	if( $content =~ /<a href="([^"]+)"[^>]+>&gt;&gt;<\/a>/ ) #"
	{
		$np = "http://www.rosfirm.ru$1";
	}
	return $np;
}

sub get_companies {
	my ($content, $data_ref) = @_;
	
	while ( $content =~ /<span class="firm_name">\s<a href="([^"]+)"\starget="_blank">\s(.+?)\s<\/a>\s<\/span>/g ) #"
	{
		push @$data_ref, {
			name => $2,
			url => $1
		};
	}
}

sub get_categories {
	my ($content, $data_ref) = @_;
	# process columns
	my @columns = $content =~ /<td class="column_catalog">(.+?)<\/td>/g;
	foreach my $column (@columns){
		# remove spare divs
		$column =~ s/<div class="sprav_sub">.*?<\/div>//g;
		# extract category names and links
		while ( $column =~ /<a href="([^"]+)">(.+?)<\/a>/g ) #"
		{
			push @$data_ref, {
				name => $2,
				url => $1
			};
		}
	}
}

sub check_content_type {
	my $content = shift;
	if ( $content =~ /<table class="catalog_table"> <tr><td class="column_catalog">/ ) {
		return $type_categories;
	} else {
		return $type_companies;
	}
}

#################################### OTHER FUNCTIONS ######################################

sub insert_categories {
	my ($parent_id, $data_ref) = @_;
	
	my $sql = "insert into Category (Category_ID, Name, URL) values (?, ?, ?)";
	my $sth = $dbh->prepare($sql);
	foreach my $row (@$data_ref){
		$sth->execute($parent_id, $row->{name}, 'http://www.rosfirm.ru'.$row->{url}) or die "SQL Error: ".$dbh->err;
	}
	$sth->finish();
	
	$sql = "update Category set Status=$status_done where ID=$parent_id";
	do_query($dbh, sql=>$sql);
	
}

sub insert_companies {
	my ($parent_id, $next_page, $data_ref) = @_;
	
	my $sql = "insert into Company (Category_ID, Name, URL) values (?, ?, ?)";
	my $sth = $dbh->prepare($sql);
	foreach my $row (@$data_ref){
		$sth->execute($parent_id, $row->{name}, $row->{url}) or die "SQL Error: ".$dbh->err;
	}
	$sth->finish();
	
	if($next_page){
		$sql = "update Category set URL='$next_page', Status=$status_ready where ID=$parent_id";
	} else {
		$sql = "update Category set Status=$status_done where ID=$parent_id";
	}
	
	do_query($dbh, sql=>$sql);
	
}

sub get_opened_categories {
	my ($dbh, $count) = @_;
	my $sql = "select * from Category where Status=$status_ready limit $count";
	
	my @rows = do_query($dbh, sql=>$sql);
	
	# mark the categories as 'processing'
	my $idstr = join ',', map { $_->{ID} } @rows;
	
	$sql = "update Category set Status=$status_processing where ID in ($idstr)";
	do_query($dbh, sql=>$sql);
	$dbh->commit();
	
	return \@rows;
}

sub check_first_start {
	my ($dbh) = @_;
	my $sql = 'select count(*) from Category';
	my ($row) = do_query($dbh, sql=>$sql, arr_ref=>1);
	if ($row->[0]){
		print "Continue work\n";
		# some records might have 'processing' status, we should switch them to 'ready'
		$sql = "update Category set Status=$status_ready where Status=$status_processing";
		do_query($dbh, sql=>$sql);
	} else {
		# if it is the first start then we should add a root category
		print "First start\n";
		$sql = "insert into Category (URL, Name) values ('http://www.rosfirm.ru/catalog/', 'Root')";
		do_query($dbh, sql=>$sql);
	}
	$dbh->commit();
}

sub pretty_content {
	my $content = shift;
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	return $content;
}

sub safe_get {
	my $url = shift;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	while (!$mech->get($url)){
		print "Error getting $url\n";
		sleep 1;
	}
	return $mech->content();
}

sub get_dbh {
	my $dbhx = DBI->connect("dbi:mysql:rosfirma",'root','admin') or die "Connection Error: $DBI::errstr\n";
	$dbhx->{'mysql_enable_utf8'} = 1;
	$dbhx->do("set names utf8");
	$dbhx->{AutoCommit} = 0;
	return $dbhx;
}

sub do_query {
	my $dbh = shift;
	my %params = @_;
	
	my $sql 	= $params{sql};
	my $hashref = exists $params{hashref} ? $params{hashref} : 0;
	my $arr_ref = exists $params{arr_ref} ? $params{arr_ref} : 0;
	
	my $sth = $dbh->prepare($sql);
	$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)";
	
	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} elsif($hashref) {
		$rows = $sth->fetchall_arrayref({});
	} elsif($arr_ref) {
		$rows = $sth->fetchall_arrayref([]);
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	return wantarray ? @{$rows} : $rows;
}
