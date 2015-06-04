use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Product;

# I don't know why but products have too many images with the same links.
# the duplicates have to be deleted.
do_filter_data();

exit;


sub do_filter_data {
	
	my $dbh = get_dbh();
	
	print "Started\n";
	
	my $products = Product->new->selectAll($dbh);
	
	print scalar @$products;
	print " products\n";
	
	foreach my $prod (@$products){
		
		my $pid = $prod->get("ID");
		print "$pid\n";
		
		my $commit = 0;
		
		my $pp = ProductPicture->new();
		$pp->set('Product_ID', $pid);
		
		my @piclist = $pp->listSelect($dbh);
		
		my %pichash;
		foreach my $pp_obj (@piclist){
			my $url = $pp_obj->get("URL");
			if(exists $pichash{$url}){
				# delete
				$commit = 1;
				unlink $pp_obj->getStoragePath();
				$pp_obj->delete($dbh);
			}else{
				$pichash{$url} = 1;
			}
		}
		
		$dbh->commit() if $commit;
		
		print scalar @piclist;
		print "/";
		print scalar keys %pichash;
		print "\n";
		
	}
	
	
	release_dbh($dbh);	
}

