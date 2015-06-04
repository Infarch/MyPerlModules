use strict;
use warnings;

use DB_Member;
use ISoft::Conf;
use ISoft::DB;


# database connection settings
our $db_name = $constants{Database}{DB_Name};
our $db_user = $constants{Database}{DB_User};
our $db_pass = $constants{Database}{DB_Pass};
our $db_host = $constants{Database}{DB_Host};



my $dbh = get_dbh();

my $tmp_obj = DB_Member->new;
$tmp_obj->set('Type', 2);

print "Loading...\n";

my $list = $tmp_obj->listSelect($dbh);

print scalar @$list, " items\n";

my @full;
my @chat;
my @narod;
my @euro;

foreach my $obj (@$list){
	
	my $url = $obj->get('URL');
	push @full, $url;
	
	my $result;
	
	if($result = check_domain('chat.ru', $url)){
		push @chat, $result;
	} elsif ($result = check_domain('narod.ru', $url)) {
		push @narod, $result;
	} elsif ($result = check_domain('euro.ru', $url)) {
		push @euro, $result;
	}
	
}

print "Done\n";

save_lines('full.txt', \@full);
save_lines('chat.txt', \@chat);
save_lines('narod.txt', \@narod);
save_lines('euro.txt', \@euro);



$dbh->rollback;
exit;

# ------------------------------------------------------------------------

sub save_lines {
	my ($file, $list_ref) = @_;
	
	open DEST, '>:encoding(UTF-8)', $file or die "Cannot open file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}


sub check_domain {
	my ($name, $url) = @_;
	
	if( $url =~ /(^http:\/\/(www.|))(.*?\b$name.*)/i ){
		my $begin = $1;
		my $end = $3;
		
		if( $end =~ /^([^\/]+)\/~([^\/]+)(.*)/ ){
			my $domain = $1;
			my $account = $2;
			my $rest = $3 || '';
			
			$url = "$begin$account.$domain$rest";
			
		}
		
		return $url;
	}
	
	return undef;
	
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass, $db_host);
}

