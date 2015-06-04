use strict;
use warnings;

use LWP::Simple 'get';
use LWP::UserAgent;

use HTML::TreeBuilder::XPath;
use URI;


my $site = 'http://2ip.ru/';

my $ua = LWP::UserAgent->new();
$ua->timeout(20);

my $proxy = '195.168.109.60:8080';

$ua->proxy('http', "http://$proxy");
my $resp = $ua->get($site);

die unless $resp->is_success();


my $content = $resp->content;
print get_ip( $content );






sub get_ip{
	my $content = shift;
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	return $tree->findvalue( q{//div[@class='ip']/big} );
}

