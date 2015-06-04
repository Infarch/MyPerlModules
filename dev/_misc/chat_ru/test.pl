use strict;
use warnings;

use Encode 'encode';
use HTML::TreeBuilder::XPath;
use LWP::Simple 'get';

use Parsers;

# this script tests Parsers.pm


#my $tree = HTML::TreeBuilder::XPath->new;
#$tree->parse_content(get('http://chat.ru/catalog/Biznes_i_karera-81-100/'));


# select one or more tests by uncomment required lines

#test_get_categories($tree, 1);

test_get_products(get('http://chat.ru/catalog/Biznes_i_karera-81-100/'));

#test_get_product_info($tree);

#test_get_product_picture($tree);

#test_get_product_additional_pictures($tree);

#test_get_next_page($tree);





# ------------------------------------------------------------------------

sub test_get_next_page {
	my $tree = shift;
	print "Next page: ", get_next_page($tree);
	print "\n";
}

sub test_get_product_additional_pictures {
	my $tree = shift;
	print "Test a product additional pictures:\n";
	my $plist = get_product_additional_pictures($tree);
	print_hashlist($plist);
	print "\n";
}

sub test_get_product_picture {
	my $tree = shift;
	print "Test a product picture:\n";
	my $pdata = get_product_picture($tree);
	print_hash($pdata);
	print "\n";
}

sub test_get_product_info {
	my $tree = shift;
	print "Test a product:\n";
	my $pdata = get_product_info($tree);
	print_hash($pdata);
	print "\n";
}

sub test_get_products {
	my $tree = shift;
	print "Test products:\n";
	my $plist = get_products($tree);
	print_hashlist($plist);
	print "\n";
}

sub test_get_categories {
	my ($tree, $level) = @_;
	print "Test categories at level $level:\n";
	my $clist = get_categories($tree, $level);
	print_hashlist($clist);
	print "\n";
}





############# utilites #############

sub print_hashlist {
	my $lref = shift;
	print "List contains ", scalar @$lref, " items\n";
	foreach my $item (@$lref){
		print_hash($item);
		print "----------------\n";
	}
}

sub print_hash {
	my $href = shift;
	while( my($key, $value)=each %$href ){
		my $str = encode('cp866', "$key -> $value");
		print "$str\n";
	}
}