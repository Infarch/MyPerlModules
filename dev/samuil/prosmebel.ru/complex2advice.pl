use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use Category;
use Product;

use ISoft::Conf;
use ISoft::DBHelper;


my $dbh = get_dbh();

my $cat_obj = Category->new;
$cat_obj->set("URL", "http://www.prosmebel.ru/complect/%");
$cat_obj->setOperator("URL", "like");
$cat_obj->markDone();
my @list = $cat_obj->listSelect($dbh);

foreach my $tmp_obj (@list){
	
	my $parent_id	= $tmp_obj->get("Category_ID");
	my $url = $tmp_obj->get("URL");
	my $allow_advice = $url ne 'http://www.prosmebel.ru/complect/none';
	
	# get products
	my @prods = $tmp_obj->getProducts($dbh);

	my @ids = map { $_->ID } @prods;
	
	foreach my $prod_obj (@prods){
		# change the parent directory
		$prod_obj->set("Category_ID", $parent_id);
		if($allow_advice){
			my $pid = $prod_obj->ID;
			my @adv = grep { $_ != $pid } @ids;
			$prod_obj->set("Advice", join ';', @adv);
		}
		$prod_obj->update($dbh);
	}
	
	$tmp_obj->markFailed();
	$tmp_obj->update($dbh);
	
	$dbh->commit();
	
}




release_dbh($dbh);
