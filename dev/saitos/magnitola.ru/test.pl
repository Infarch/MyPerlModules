use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use Encode qw /decode encode/;

use Parsers;

# http://magnitola.ua/Parrot-Driver-Headset-p-10537.html
# http://magnitola.ua/MLux-ballast-35W-p-13018.html


my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse_content(get('http://magnitola.ru/Ground-Zero-GZTA-4-120-MK2-p-11172.html'));



#test_get_categories($tree, 1);

#test_get_products($tree);

#test_get_next_page($tree);

test_get_product_info($tree);

#test_get_product_picture($tree);

#test_get_product_additional_pictures($tree);







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
		my $str = "$key = $value";
		$str = encode('cp866', $str);
		print "$str\n";
	}
}

sub get {
	my $url = shift;
	
	my $agent = LWP::UserAgent->new;
	my $resp = $agent->get($url);
	
	return $resp->is_success ? $resp->decoded_content : '';
	
}
