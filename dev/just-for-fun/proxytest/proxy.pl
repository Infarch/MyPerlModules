use strict;
use warnings;

use WWW::Mechanize;

my $mech = WWW::Mechanize->new();

#$mech->proxy(['http'], 'http://79.133.68.246/');
#$mech->proxy(['http'], 'http://democracy.dreamworks.com/');
#$mech->proxy(['http'], 'http://211.138.124.210/');
$mech->proxy(['http'], 'http://123.233.121.164/');




$mech->get('http://proverim.net/proxy1.php');
#$mech->get('http://google.com');

open FF, '>page_new.htm';
binmode FF;
print FF $mech->content();
close FF;
