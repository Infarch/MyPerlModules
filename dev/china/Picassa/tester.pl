use strict;
use warnings;

use LWP::UserAgent;
use URI::Escape;


my $text = "http://lh6.ggpht.com/_CxysVoUXW90/TSva_TJJB5I/AAAAAAAA900/__fB6zbPTrI/Jeffrey%20Campbell-12%20%282%29.jpg";
my @parts = split '/', $text;

my $last = pop @parts;

print uri_unescape($text);
print "\n";

my $ag = LWP::UserAgent->new;
my $r = $ag->get( uri_unescape($text) );

if($r->is_success()){
	print "ok\n";
}

