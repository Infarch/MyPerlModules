use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib", "local_lib");

use Feature;

use ISoft::Conf;
use ISoft::DBHelper;

print "\nSTART\n\n";

my $agent = LWP::UserAgent->new;
my $cookes = HTTP::Cookies->new();
$agent->cookie_jar( $cookes );

$agent->agent('Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0');
$agent->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());
$agent->default_header('Accept-Language' => "en-us,en;q=0.5");
$agent->default_header('Host' => "www.lights-depot.com");
$agent->default_header('Referer' => "http://www.lights-depot.com/console.php?dispatch=auth.login_form&return_url=console.php");

my $resp = $agent->post('http://www.lights-depot.com/console.php', {
	'return_url' => 'console.php',
	'user_login' => 'evgeniy@lights-depot.com',
	'password' => '1234560',
	'dispatch[auth.login]' => 'Sign in'
});

die "Bad code" if $resp->code != 302;

#print $resp->headers_as_string, "\n-----------\n";
#print $resp->request()->headers_as_string, "\n-----------\n";
#print $cookes->as_string, "\n-----------\n";

# lights-depot.com/console.php?dispatch=products.manage&items_per_page=100&page=1

# PRODUCTS

$agent->default_header('Accept' => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
$agent->default_header('Referer' => "http://www.lights-depot.com/console.php?dispatch=products.manage");
$agent->default_header('Connection' => "keep-alive");

# ask the list of products
my $work;
do {

	my $resp = $agent->get('http://lights-depot.com/console.php?dispatch=products.manage');
	my $content = $resp->decoded_content();
	print $resp->code, "\n";
	print $resp->request()->headers_as_string, "\n-----------\n";
	print $resp->headers_as_string, "\n-----------\n";
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	
	my @list = $tree->findnodes( q{.//*[@id='pagination_contents']/table/tr/td[1]/input} );
	$work = @list > 0;
	
	print @list;
	
	die;
	
	
} while ($work);



# FEATURES

# load features
#my $dbh = get_dbh();
#my @features = Feature->new()->selectAll($dbh);
#release_dbh($dbh);

# remove all them
#foreach my $feature (@features) {
#	my $fid = $feature->get('CartID');
#	next if $fid == 11;
#	print $fid, "\n";
#	my $url = "http://www.lights-depot.com/console.php?dispatch=product_features.delete&feature_id=$fid&result_ids=pagination_contents";
#	$agent->get($url);
#}



print "Done\n";

