use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;

my $agent = LWP::UserAgent->new;

my $site = "http://www.yahoo.com/";

$agent->proxy('http', "http://213.186.218.141:80");

my $resp = $agent->get($site);
if($resp->is_success()){
	print "Ok\n";
}

