use strict;
use warnings;

use XML::LibXML;

use lib ("/work/perl_lib", "local_lib");

use ISoft::DBHelper;
use Category;
use Product;



start();


exit;

#--------------------------

sub start {

	my $dbh = get_dbh();
	
	
	my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $root = $dom->createElement('muztorg');
	$dom->setDocumentElement($root);

	my $root_obj = Category->new;
	$root_obj->set('Level', 0);
	$root_obj->select($dbh);
	
	add_category($dbh, $root, $root_obj);
	
	release_dbh($dbh);	
	
	open XX, '>report.xml';
	print XX $dom->toString(1);
	close XX;
	
}

sub add_category {
	my ($dbh, $root, $category_obj) = @_;
	
	my $node = $root->addNewChild(undef, 'category');
	$node->setAttribute('cid', $category_obj->ID);
	my $name = $node->addNewChild(undef, 'name');
	$name->appendText($category_obj->get('Name') || 'root');
	
	my $pc = 0;
	
	# get child categories
	my $new_cat_obj = $category_obj->new;
	$new_cat_obj->set('Category_ID', $category_obj->ID);
	my @catlist = $new_cat_obj->listSelect($dbh);
	
	if(@catlist>0){
		my $children = $node->addNewChild(undef, 'subcategories');
		foreach my $c (@catlist){
			$pc += add_category($dbh, $children, $c);
		}
	}
	
	# get products
	my $new_prod_obj = $category_obj->newProduct();
	$new_prod_obj->set('Category_ID', $category_obj->ID);
	my @prodlist = $new_prod_obj->listSelect($dbh);
	
	if(@prodlist>0){
		my $children = $node->addNewChild(undef, 'products');
		foreach my $p (@prodlist){
			$pc++;
			add_product($dbh, $children, $p);
		}
	}
	
	$node->setAttribute('pcount', $pc);
	return $pc;
}

sub add_product {
	my ($dbh, $root, $product_obj) = @_;
	
	my $node = $root->addNewChild(undef, 'product');
	$node->setAttribute('pid', $product_obj->ID);
	my $name = $node->addNewChild(undef, 'name');
	$name->appendText($product_obj->get('Name'));
	
}