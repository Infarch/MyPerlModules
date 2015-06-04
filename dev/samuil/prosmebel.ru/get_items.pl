use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode;
use Audio::Beep;

use ISoft::Conf;
use ISoft::DBHelper;

use Product;

die "Done";


my %match_ignore = map { $_ => 1 } (
	 90,  102,  392,  409,  470,  471,  509,  541,  553,  576,  580,  582,
	687,  734,  739,  790,  840,  845,  858,  867,  884,  901,  917,  919,
	939,  949,  975,  980, 1000, 1014, 1017, 1095, 1155, 1167, 1168, 1211,
	1216, 1235, 1238, 1247
);


my $agent = LWP::UserAgent->new;

my $dbh = get_dbh();

my $obj = Product->new;
$obj->set("Status", 2);
my @list = $obj->listSelect($dbh);
print scalar @list, " products\n";

foreach my $prod_obj ( @list ){
	
	my $url = $prod_obj->get("URL");
	my $pid = $prod_obj->ID;
	
	print "$pid: $url\n";
	
	
	my $resp = $agent->get($url);
	if($resp->is_success){
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($resp->decoded_content());
		
		# method 1
		my $name = $tree->findvalue( q{//div[@class='product_detail']/div[1]/div[@class='product_right']/h1[@itemprop='name']} );
		
		unless($name){
			# method 2
			$name = $tree->findvalue( q{//div[@id='container']/div[@id='content']/div[@id='main']/h1} );
		}
		
		die "No name" unless $name;
		
		my $old_name = $prod_obj->Name;
		$old_name =~ s/&amp;/&/g;
		
		if(index(lc($name), lc($old_name)) == -1 && !exists $match_ignore{$pid}){
			beep(1000, 500);
			print Encode::encode('cp866', $name) . " does not like to " . Encode::encode('cp866', $old_name);
			print "\nPress ENTER to overwrite...\n";
			<>
		}
		
		$tree->delete();
		
		# update the product's name and status
		$prod_obj->set("Name", $name);
		$prod_obj->set("Status", 3);
		$prod_obj->update($dbh);
		$dbh->commit();
		
	}else{
		print "Request failed\n";
	}
	
	
	#last;
}

release_dbh($dbh);

print "Done\n";
