use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ProductDescriptionPicture;

use ISoft::Conf;
use ISoft::DBHelper;


use File::Copy;
use LWP::UserAgent;

my $agent = LWP::UserAgent->new;

my $dbh = get_dbh();

my $pdp_obj = ProductDescriptionPicture->new;
$pdp_obj->set("Status", 0);
my @list = $pdp_obj->listSelect($dbh);

foreach my $obj (@list){
	
	my $id = $obj->ID;
	print "$id\n";
	
	my $url = $obj->get("URL");
	
	if( $url =~ /(.+)\/(.+)\.(.+)/ ){
		my $path = $1;
		my $org_name = $2;
		my $org_ext = $3;
		my $new_name = sprintf "pd_%05d.$org_ext", $id;
		
		$obj->set("Local_Filename", $new_name);
		
	}else{
		die "Bad URL $url\n";
	}
	
	my $resp = $agent->get($url);
	die "Failed" unless $resp->is_success;
	$obj->processResponse($dbh, $resp);
	$dbh->commit();
	
}








release_dbh($dbh);
