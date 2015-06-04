use strict;
use warnings;

use LWP::Simple 'get';

use HTML::TreeBuilder::XPath;



my $url = 'http://yaca.yandex.ru/yca/cat/';

my $content = get($url);
my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse_content($content);

my $c = q{//div[@class='b-rubric__layout__cell']//a[@class='b-rubric__list__item__link' or @class='b-additional-links__link ']};

my @nodes = $tree->findnodes( $c );
foreach my $node (@nodes){
	
	next if $node->attr('style');
		
	print $node->findvalue( q{./@href} );
	print "\n";
}
