use strict;
use warnings;


# check whether any page includes 'vimeo' string

use Storable qw(freeze thaw);
use Digest::MD5 qw(md5_hex);

use lib ("/work/perl_lib", "local_lib");

use ISoft::ParseEngine::ThreadProcessor;
use ISoft::DB;
use ISoft::DBHelper;


use Product;



test();


# ----------------------------

sub test {
	
	# get database handler
	my $dbh = get_dbh();
	
	
	my $p = Product->new();
	$p->set('EmbedSrc', undef);
	$p->set('Status', 3);
	
	my @list = $p->listSelect($dbh);
	
	print scalar @list;
	
	foreach my $prod (@list){
		my $pid = $prod->ID;
		
		print "$pid\n";
		
		my $key = md5_hex($prod->get("URL"));
		# look into cache for the key
		my ($row) = ISoft::DB::do_query($dbh, sql=>"select * from `cache` where `Key`='$key'");
		if(defined $row){
			my $resp = thaw($row->{Content});
			my $content = $resp->decoded_content;
			
			if($content!~/http:\/\/flv\.5678\.ru\/v\//){
				die "NOT Found: ".$pid;
			}
			
		}
		else{
			die "No cache: ".$pid;
		}
		
	}
	
	release_dbh($dbh);
}

