use strict;
use warnings;


use lib ("/work/perl_lib", "local_lib");

use ISoft::DBHelper;
use ISoft::ParseEngine::XmlReport;
use Category;
use Product;

start();


exit;

#--------------------------

sub start {

	my $dbh = get_dbh();
	my $cat_obj = Category->new;
	$cat_obj->set('Level', 0);
	$cat_obj->select($dbh);
	
	my $prod_obj = Product->new;
	my @columns = grep { /^Prop/ } keys( %{$prod_obj->{Columns}} );
	unshift @columns, 'URL', 'Description', 'Vendor';
	ISoft::ParseEngine::XmlReport::make_file($dbh, 'report.xml', $cat_obj, 
		pretty=>0, 
		prod_limit=>10, 
		prod_columns=>\@columns);
	
	release_dbh($dbh);
	
}

