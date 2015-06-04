package ISoft::ParseEngine::XmlReport;

use strict;
use warnings;



use XML::LibXML;



sub make_xml {
	my ($dbh, $root_obj, %params) = @_;

	my $rootname = $params{rootname} || 'catalog';
		
	my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $root = $dom->createElement($rootname);
	$dom->setDocumentElement($root);

	add_category($dbh, $root, $root_obj, %params);

	return $dom;	
}

sub make_file {
	my ($dbh, $file_name, $root_obj, %params) = @_;
	
	my $pretty = exists $params{pretty} ? $params{pretty} : 1;
	
	my $dom = make_xml($dbh, $root_obj, %params);

	open XX, ">$file_name";
	print XX $dom->toString($pretty);
	close XX;

}


sub add_category {
	my ($dbh, $root, $category_obj, %params) = @_;
	
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
			$pc += add_category($dbh, $children, $c, %params);
		}
	}
	
	# get products
	my $new_prod_obj = $category_obj->newProduct();
	$new_prod_obj->set('Category_ID', $category_obj->ID);
	$new_prod_obj->markDone();
	$new_prod_obj->maxReturn($params{prod_limit}) if exists $params{prod_limit};
	my @prodlist = $new_prod_obj->listSelect($dbh);
	
	if(@prodlist>0){
		my $children = $node->addNewChild(undef, 'products');
		foreach my $p (@prodlist){
			$pc++;
			add_product($dbh, $children, $category_obj, $p, %params);
		}
	}
	
	$node->setAttribute('pcount', $pc);
	return $pc;
	
}

sub add_product {
	my ($dbh, $root, $category_obj, $product_obj, %params) = @_;
	
	my $node = $root->addNewChild(undef, 'product');
	$node->setAttribute('pid', $product_obj->ID);
	my $name = $node->addNewChild(undef, 'name');
	$name->appendText($product_obj->get('Name'));
	
	if( my $cols = $params{prod_columns} ){
		my @columns;
		if(ref $cols eq 'CODE'){
			@columns = $cols->($category_obj, $product_obj);
		} elsif (ref $cols eq 'ARRAY'){
			@columns = @$cols;
		} else {
			die "Bad column definition";
		}
		
		foreach my $col (@columns){
			my $val = $product_obj->get($col);
			if(defined $val){
				my @variants = split '-!-', $val;
				if(@variants > 1){
					my $prop_node = $node->addNewChild(undef, $col)->addNewChild(undef, 'variants');
					foreach my $variant (@variants){
						$prop_node->addNewChild(undef, 'variant')->appendText($variant);
					}
				} else {
					my $prop_node = $node->addNewChild(undef, $col);
					$prop_node->appendText($val);
				}
			}
		}		
	}
	
}











1;
