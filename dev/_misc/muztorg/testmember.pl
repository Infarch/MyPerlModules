use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::ParseEngine::Member;


my $member = new ISoft::ParseEngine::Member();
$member->set('URL', 'http://isoft.ho.ua/headers.cgi');

my $agent = LWP::UserAgent->new;
my $resp = $agent->request( $member->getRequest() );
print $resp->content();


