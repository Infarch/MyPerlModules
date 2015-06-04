use strict;
use warnings;


use lib ("/work/perl_lib", "local_lib");


use ISoft::Conf;
use ISoft::DB;
use ISoft::DBHelper;

use Product;
use Translit;

our %catCache; # page_id => category_id

our @collector; # values to be inserted

our %prodnumbers;

our $script_dir = $constants{DestinationFiles}{SCRIPT_DIR};

our $dbh = get_dbh();

start();

release_dbh($dbh);

exit;

#####################################################################

sub start {
	
	my $prodlist = get_products($dbh);
	
	print scalar @$prodlist, " products to be processed\n";

	# generate tags for each product
	process_product($_) || print "Failed $_->{ID}\n" foreach @$prodlist;
	
	# save file
	open XX, ">$script_dir/vendors.sql";
	print XX "INSERT INTO `SC_category_product` (`productID`, `categoryID`) VALUES\n";
	print XX join ",\n", @collector;
	print XX ";\n\n";
	
	# update product count
	foreach my $key (keys %prodnumbers){
		print XX "UPDATE `SC_categories` set `products_count`=`products_count`+$prodnumbers{$key} where `categoryID`=$key;\n";
	}
	
	close XX;
	
}

sub process_product {
	my $row = shift;
	
	#check whether the product exists in local database using it's code
	my $id = $row->{ID};
	my $code = $row->{Code};
	
	my $prod = Product->new;
	$prod->set('InternalID', $code);
	$prod->markDone();
	unless ($prod->checkExistence($dbh)){
		print "No product $code\n";
		return 0;
	}
	
	my $prod_id = $prod->ID;
	my $vendor = $prod->get('Vendor');
	my $page_id = "vendors-".Translit::convert($vendor);
	$page_id =~ s/[, ]+/-/g;
	$page_id =~ s/[.']+//g; #'
	
	# get a category having such page_id
	unless (exists $catCache{$page_id}){
		my $rows = ISoft::DB::do_query($dbh, sql=>"SELECT categoryID FROM `SC_categories` WHERE slug = ?", values=>[$page_id]);
		if(@$rows==0){
			print "No page $page_id\n";
			return 0;
		}
		$catCache{$page_id} = $rows->[0]->{categoryID};
	}
	my $cat_id = $catCache{$page_id};
	
	push @collector, "($id,$cat_id)";

	unless(exists $prodnumbers{$cat_id}){
		$prodnumbers{$cat_id} = 0;
	}
	$prodnumbers{$cat_id} += 1;
	
	return 1;
}

sub get_products {
	my $dbh = shift;
	
	my $sql = "select productID as ID, product_code as Code from sc_products  where product_code like 'ilc-%'";
	my $rows = ISoft::DB::do_query($dbh, sql=>$sql);
	
	return $rows;
	
}
