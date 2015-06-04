package Parser;

use strict;
use warnings;

use LWP::UserAgent;

use Data::Dumper;
use Encode qw(encode decode from_to);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $dbh = shift;
  
  # init agent
  my $browser = LWP::UserAgent->new;
  
  my %self  = (
	  dbh  => $dbh,
	  browser => $browser,
	  update => 0,
	  properties => undef,
	  categories => undef,
	  @_ # init
  );
  my $self = bless( \%self, $class );
  
  # get all properties and categories, in order to avoid spare database requests in runtime
  $self->properties( $self->cacheTable("property") );
  $self->categories( $self->cacheTable("category") );
  
  return $self;
}

sub cleanData {
	my ($self, $data) = @_;
	
	$data =~ s/&nbsp;/ /ig;
	
	return $data;
}

# get all rows from the specifed table. the 'name_eng' field will be used as a key.
sub cacheTable {
	my ($self, $table) = @_;
	my @rows = $self->doQuery(sql=>"select * from $table");
	my %cache;
	foreach my $row (@rows){
		$cache{ $row->{name_eng} } = $row;
	}
	return \%cache
}

# the start point for parsing. returns array of links to IMO ranges
sub getImoRangeLinks {
	my $self = shift;
	
	my $content = $self->fetch("http://www.rs-head.spb.ru/ru/regbook/file_shipr/main_r_imo.php");
	my @list;
	while( $content=~/<td class="tr_regname" valign="top">\s<A HREF="(.*?)">.*?<\/A>\s<\/td>/g ){
		push @list, "http://www.rs-head.spb.ru/ru/regbook/file_shipr/$1";
	}
	
	return @list;
}

# the second point for parsing. takes a link to IMO range and returns list of RS numbers
sub getRsFromImoRange {
	my ($self, $url) = @_;
	
	my $content = $self->fetch($url);
	
	my @list;
	while( $content=~/<tr class="trt_all">\s<td class="tr_regname" valign="top">\s<A HREF="http:\/\/www\.rs-head\.spb\.ru\/app\/fleet\.php\?index=(\d+)&type=book1&language=(rus|eng)">\d+<\/A>\s<\/td>\s<\/tr>/g ){
		push @list, $1;
	}
	
	return @list;
}

# main function processing the specified registry number
sub process_rs {
	my ($self, $rs) = @_;

	my $query = {
		rsnum => $rs
	};
	my ($obj) = $self->doSelect("ship", $query);
	
	my $msg;
	if(defined $obj){
		if(!$self->update()){
			print "Skipped $rs\n";
			return;
		}
		$query->{id} = $obj->{id};
		$msg = "Updated RS $rs\n";
	} else {
		$msg = "Processed RS $rs\n";
	}
	
	my $content_eng = $self->fetch( $self->makeShipUrl($rs, "eng") );
	my $properties_eng = $self->parseShipProperties($content_eng);

	my $content_rus = $self->fetch( $self->makeShipUrl($rs, "rus") );
	my $properties_rus = $self->parseShipProperties($content_rus);
	
	
	my $owner_id = $self->getShipOwnerID($content_eng);
	$self->processOwner($owner_id);
	$query->{shipowner_id} = $owner_id;

	my $ship_id = $self->processShip($query, $properties_eng->{"GENERAL INFORMATION"});
	
	$self->processShipProperties($ship_id, $properties_eng, $properties_rus);
	
	print $msg;
	
}

# iserts/updates a ship's properties
sub processShipProperties {
	my ($self, $ship_id, $properties_eng, $properties_rus) = @_;
 	
 	# get cached categories and properties
 	my $cache_cat = $self->categories();
 	my $cache_prop = $self->properties();
 	
 	# loop through english categories
 	while( my($cat_eng,$vals_eng) = each %$properties_eng ){

 		# get russian analog
 		my $cat_rus = $cache_cat->{$cat_eng}->{name_rus} || die "No russian category analog for $cat_eng";
 		# get russian values
 		my $vals_rus = $properties_rus->{$cat_rus} || die "No russian values for $cat_eng";
 		
 		# loop through english values
 		while( my($prop_name_eng,$prop_value_eng) = each %$vals_eng ){
 			# look for russian property name
 			my $prop_name_rus = $cache_prop->{$prop_name_eng}->{name_rus} || die "No russian property analog for $prop_name_eng";
 			# look for russian property value
 			my $prop_value_rus = exists $vals_rus->{$prop_name_rus} ? $vals_rus->{$prop_name_rus} : die "No russian value for $prop_name_eng";
 			my $property_id = $cache_prop->{$prop_name_eng}->{id};
 			
 			# check existence of Value
 			my $query = {
 				property_id => $property_id,
 				ship_id => $ship_id
 			};
 			
 			my ($obj) = $self->doSelect("value", $query);
 			my $update;
 			if(defined $obj){
 				$update = 1;
 				$query = $obj;
 			}
 			# some properties contain links, remove them
 			$prop_value_eng =~ s/<a.*?>//i;
 			$prop_value_eng =~ s/<\/a>//i;
 			$prop_value_rus =~ s/<a.*?>//i;
 			$prop_value_rus =~ s/<\/a>//i;
 			
 			# set values
 			$query->{value_eng} = $prop_value_eng;
 			$query->{value_rus} = $prop_value_rus;
 			# register it
 			$update ? $self->doUpdate("value", "id", $query) : $self->doInsert("value", $query);
 		}
 	}
}

# checks existence of a ship with the specified registry number.
# insert / updates 'ship' table.
# returns ship's id
sub processShip {
	my ($self, $query, $general_properties) = @_;
	
	# extract several english properties
	while( my($key,$value) = each %$general_properties ){
		if($key eq 'IMO number'){
			$query->{imonum} = $value;
		} elsif ($key eq 'Call sign'){
			$query->{callsign} = $value;
		}
	}
	
	if(exists $query->{id}){
		$self->doUpdate("ship", "id", $query);
		return $query->{id};
	} else {
		return $self->doInsert("ship", $query);
	}

}

# extract / update a ship's owner data according to specified id.
# note that the id is 'external_id' field.
# returns database id of the owner.
sub processOwner {
	my ($self, $ext_id, $lang) = @_;

	# check whether the owner already exists in database
	my $query = {
		external_id => $ext_id
	};
	my ($obj) = $self->doSelect("shipowner", $query);
	if( defined($obj) && !$self->update() ){
		print "Skipped owner $ext_id\n";
		return $obj->{id};
	}
	
	my $content_eng = $self->fetch( $self->makeOwnerUrl($ext_id, "eng") );
	my $content_rus = $self->fetch( $self->makeOwnerUrl($ext_id, "rus") );
	
	my $properties_eng = $self->parseOwnerProperties($content_eng);
	my $properties_rus = $self->parseOwnerProperties($content_rus);
	
	my $id;
	
	$query->{name_eng}   = $properties_eng->{name};
	$query->{adress_eng} = $properties_eng->{address};
	$query->{phone}      = $properties_eng->{phone};
	$query->{fax}        = $properties_eng->{fax};
	$query->{email}      = $properties_eng->{email};
	$query->{telex}      = $properties_eng->{telex};
	$query->{web}        = $properties_eng->{web};
	$query->{name_rus}   = $properties_rus->{name};
	$query->{adress_rus} = $properties_rus->{address};

	if(defined $obj){
		$id = $obj->{id};
		$query->{id} = $id;
		$self->doUpdate("shipowner", "id", $query);
	} else {
		$id = $self->doInsert("shipowner", $query);
	}
	
	return $id;
}

sub parseOwnerProperties {
	my ($self, $content) = @_;
	
	my %data;
	
	# name
	if($content=~/<td width="85%"><B style="font-size:14pt">\s?&nbsp;(.*?)<\/B>/){
		$data{name} = $1;
	}
	
	# others
	my @others;
	while($content=~/<TR><td width="85%">[^:]+:\s?&nbsp;(.*?)<\/td><TD><\/TD><\/TR>/g){
		push @others, $1;
	}
	
	$data{address} = $self->cleanData( $others[0] );
	$data{phone}   = $self->cleanData( $others[1] );
	$data{fax}     = $self->cleanData( $others[2] );
	$data{email}   = $self->cleanData( $others[3] );
	$data{telex}   = $self->cleanData( $others[4] );
	$data{web}     = $self->cleanData( $others[5] );
	
	return \%data;
	
}

sub getShipOwnerID {
	my ($self, $content) = @_;
	
	if( $content=~/http:\/\/www\.rs-head\.spb\.ru\/app\/fleet\.php\?index=(\d+)&amp;type=owner1&amp;language=/ ){
		return $1;
	} else {
		die "No ship owner";
	}
}

# returns reference to hash containing properties sorted by category
sub parseShipProperties {
	my($self, $content) = @_;
	
	$content =~ s/.+FFFFFF//;
	$content =~ s/<!--.*?-->//g;
	
	my %data;
	
	while( $content=~/<center>(.*?)<\/center>.*?<table[^>]+>(.*?)<\/table>/ig  ){
		$data{$1} = $2;
	}
	
	while( my($key,$table) = each %data ){
		my %tmp;
		while($table=~/<TR><td[^>]+>(.*?):\s?<\/td><td>\s?(&nbsp;|)(.*?)<\/t[dr]>/ig){
			$tmp{$1} = $3;
		}
		# clean data
		while( my($key2,$val) = each %tmp ){
			$tmp{$key2} = $self->cleanData( $tmp{$key2} );
		}
		$data{$key} = \%tmp;
	}
	
	return \%data;
}

# returns url of page containing ship info due to specified language
sub makeShipUrl {
	my($self, $rn, $lang) = @_;
	return "http://www.rs-head.spb.ru/app/fleet.php?index=$rn&type=book1&language=$lang";
}

# returns url of page containing owner info due to specified language
sub makeOwnerUrl {
	my($self, $id, $lang) = @_;
	return "http://www.rs-head.spb.ru/app/fleet.php?index=$id&type=owner1&language=$lang";
}

# fetches the specified page from either WEB or cache
sub fetch {
	my ($self, $url) = @_;
	
	# look for cache
	my $query = {
		url => $url
	};
	
	my $content;
	
	my ($obj) = $self->doSelect("sourcedata", $query);
	
	if(defined $obj){
		# use cache
		my $date = $obj->{cdate};
		my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
		$year+=1900;
		$mon = $self->zeropad($mon+1, 2);
		$mday = $self->zeropad($mday, 2);
		my $now = "$year-$mon-$mday";
		if($now eq $date){
			$content = $obj->{content};
		} else {
			# request the page
			$content = $self->getContent($url);
			# update cache
			$query->{content} = $content;
			$query->{id} = $obj->{id};
			$query->{cdate} = $now;
			$self->doUpdate("sourcedata", "id", $query);
		}
	} else {
		# request the page
		$content = $self->getContent($url);
		# store into cache
		$query->{content} = $content;
		$self->doInsert("sourcedata", $query);
	}
	return $content;
}

# fetches the specified page and returns it's decoded content
sub getContent {
	my ($self, $url) = @_;
	
	print "Fetching $url\n";
	
	my $response = $self->browser()->get($url);
	die "Bad response" unless $response->is_success();
	my $str = $response->decoded_content();
	$str =~ s/\r|\n|\t/ /g;
	$str =~ s/\s{2,}/ /g;
	return $str;
}

# get / set cached properties
sub properties {
	return $_[0]->_getset('properties', $_[1]);
}

# get / set cached categories
sub categories {
	return $_[0]->_getset('categories', $_[1]);
}

sub update {
	return $_[0]->_getset('update', $_[1]);
}

# get / set active browser
sub browser {
	return $_[0]->_getset('browser', $_[1]);
}

# get / set database handler
sub dbh {
	return $_[0]->_getset('dbh', $_[1]);
}

sub _getset {
	my ($self, $field, $val) = @_;
	my $old = $self->{$field};
	if(defined $val){
		$self->{$field} = $val;
	}
	return $old;
}

sub _get {
	my ($self, $field) = @_;
	return $self->{$field};
}

sub zeropad {
	my($self, $org, $count) = @_;
	return sprintf("%.${count}d",$org);
}

sub doUpdate {
	my ($self, $table, $keyfield, $values) = @_;
	
	my @field_list;
	my @val_list;
	my $id;
	foreach my $field (keys %$values){
		my $value = $values->{$field};
		if($field eq $keyfield){
			$id = $value;
		} else {
			push @field_list, "$field=?";
			push @val_list, $value;
		}
	}
	push @val_list, $id;
	
	my $field_str = join ',', @field_list;
	
	my $sql = "update $table set $field_str where $keyfield=?";
	
	$self->doQuery(sql=>$sql, values=>\@val_list, single=>1);
}

sub doInsert {
	my ($self, $table, $values) = @_;
	
	my @field_list;
	my @val_list;
	foreach my $field (keys %$values){
		my $value = $values->{$field};
		push @field_list, $field;
		push @val_list, $value;
	}
	
	my $hold_str = join ',', map {'?'} (0..$#val_list);
	my $field_str = join ',', @field_list;
	
	my $sql = "insert into $table ($field_str) values ($hold_str)";
	
	$self->doQuery(sql=>$sql, values=>\@val_list, single=>1);
	my $new_id = $self->doQuery(sql=>"select last_insert_rowid()", single=>1);
	return $new_id;
}

sub doSelect {
	my ($self, $table, $clauses) = @_;
	
	my @field_list;
	my @val_list;
	if(defined( $clauses )){
		
		foreach my $field (keys %$clauses){
			my $value = $clauses->{$field};
			push @field_list, "$field=?";
			push @val_list, $value;
		}
	}
	
	my $cstr = join ' and ', @field_list;
	$cstr = $cstr ? "where $cstr" : "";
	my $sql = "select * from $table $cstr";
	
	return $self->doQuery(sql=>$sql, values=>\@val_list); 
}

sub doQuery {
	my ($self, %params) = @_;
	my $dbh = $self->dbh();
	my $sql = $params{sql};
	my $hashref = exists $params{hashref} ? $params{hashref} : 0;
	my $arr_ref = exists $params{arr_ref} ? $params{arr_ref} : 0;
	my $single  = exists $params{single}  ? $params{single}  : 0;

	my @vals;
	if (exists $params{values}){
		my $rf = ref $params{values};
		if($rf && $rf eq 'ARRAY'){
			@vals = @{$params{values}};
		} else {
			die "The 'values' parameter should be an array reference";
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or die "SQL Error: ".$dbh->err()." ($sql)";
	} else {
		$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	}

	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} elsif($hashref) {
		$rows = $sth->fetchall_arrayref({});
	} elsif($arr_ref || $single) {
		$rows = $sth->fetchall_arrayref([]);
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	if($single){
		return @$rows>0 ? $rows->[0]->[0] : undef;
	}
	return wantarray ? @$rows : $rows;
}


1;
