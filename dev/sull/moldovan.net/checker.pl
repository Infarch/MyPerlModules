use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ISoft::DBHelper;

# Members
use Category;
use Product;


my $dbh = get_dbh();

# get root
my $root_obj = Category->new;
$root_obj->set('Level', 0);
$root_obj->select($dbh);

open my $fh, '>stat.txt';

check_category($dbh, $root_obj, $fh, '');

close $fh;

release_dbh($dbh);
exit;


sub check_category {
	my ($dbh, $category_obj, $fh, $spacer) = @_;
	
	my $pc = 0;
	
	# look for xxx
	my $xxx = Category->new;
	$xxx->set('Category_ID', $category_obj->ID);
	$xxx->set('Name', 'xxx');
	if($xxx->checkExistence($dbh)){
		my $prods_ref = $xxx->getProducts($dbh);
		$pc = @$prods_ref;
	}
	print $fh $spacer, $category_obj->Name, "  ($pc)\n";
	
	# get sub categories
	my $catlist_ref = $category_obj->getCategories($dbh);
	foreach my $item (@$catlist_ref){
		my $name = $item->Name;
		if($name eq 'xxx'){
			next;
		} else {
			check_category($dbh, $item, $fh, $spacer.'  ');
		}
	}
	
	
	
}
