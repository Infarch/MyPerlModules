use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use LWP::Simple 'get';
use LWP::UserAgent;

use DB_Prototype;
use DB_Page;




my $prot = DB_Page->new;

$prot->URL('http://www.livejournal.com/ratings/users/?page=46');

my $req = $prot->getRequest();
my $ua = LWP::UserAgent->new;
my $resp = $ua->request($req);

my $cnt = $resp->decoded_content();

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse_content($cnt);

my @nodes = $tree->findnodes( q{//table[@class='s-list rate-list']/tbody/tr/td[@class='s-list-desc']/span[@class='ljuser ljuser-name_']} );

foreach my $node(@nodes){
	my $name = $node->findvalue( q{./@lj:user} );
	my $url = $node->findvalue( q{./a[2]/@href} );
	
	if ($url !~ /\.livejournal\.com\/$/){
		print '----> ';
		
	}
	
	print "$url\n";
}























# this script tests Parsers.pm


#my $tree = HTML::TreeBuilder::XPath->new;
#$tree->parse_content(get('http://famama.ru/'));


# select one or more tests by uncomment required lines

#test_get_categories($tree, 1);

#test_get_products($tree);

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
		print "$key -> $value\n";
	}
}