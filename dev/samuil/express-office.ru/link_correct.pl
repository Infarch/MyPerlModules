use strict;
use warnings;

use Data::Dumper;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib");

use Product;
use ISoft::ParseEngine::ThreadProcessor;


my @idlist = qw(
327 589 596 658 671 722 729 986 993 994 998 1001 1014 1015 1023 1037 1039 1040 1042 1043 1058 1074 1111 1186 1187 1997 2000 2008 2009 2010 2035 2038 2039 2060 2064 2065 2067 2069 2073 2086 2091 2285 2287 2298 2299 2425 2444 2493 2498 2505 2520 2532 2537 2538 2539 2545 2546 2551 2552 2557 2558 2565 2567 2568 2569 2571 2572 2573 2574 2576 2577
);


#my $tree = HTML::TreeBuilder::XPath->new;
#$tree->parse_content($testdoc);
#my @alist = $tree->findnodes(q{//a[@href]});
#foreach my $a (@alist){
#	my $href = $a->attr('href');
#	if( $href =~ /javascript/i ){
#		my $parent = $a->parent();
#		my @x = $a->detach_content();
#		$a->postinsert(@x);
#		$a->delete();
#	}
#}



my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
my $dbh = $tp->getDbh();


my $prod_obj = Product->new;
$prod_obj->where( "description like '%javascript%'" );

my @prodlist = $prod_obj->listSelect($dbh);
my @ids = map {$_->ID} @prodlist;

print "@ids\n\n";

print "@idlist\n\n";







$dbh->rollback();

