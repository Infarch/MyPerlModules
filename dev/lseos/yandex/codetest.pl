use strict;
use warnings;
use open qw(:std :utf8);

use Encode 'decode';

use Error ':try';
use LWP::Simple 'get';
use HTML::TreeBuilder::XPath;


use lib ("/work/perl_lib");
use ISoft::DB;
use DB_Member;


my $site = 'http://www.banki.ru/';

my $ua = LWP::UserAgent->new();
$ua->timeout(20);

my $resp = $ua->get($site);

die unless $resp->is_success();

my $content = $resp->content();


my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse_content($content);
my $val = $tree->findvalue( q{//title} );

my $string;
my $ok = 0;

try {
	$string = decode('utf8', $val, Encode::FB_CROAK);
	print "Found utf8\n";
	$ok = 1;
} otherwise {
	
};

if(!$ok){
	$string = decode('koi8-u', $val, Encode::FB_CROAK);
	$ok = 1;
	print "Found koi8-u\n";
}


if(!$ok){
	$string = decode('cp1251', $val, Encode::FB_CROAK);
	print "Found cp1251\n";
}


my $dbh = ISoft::DB::get_dbh_mysql('yandex', 'root', 'admin');
my $member_obj = DB_Member->new();
$member_obj->set('Name', '');
$member_obj->set('URL', '');
$member_obj->set('Type', 5);
$member_obj->set('Status', 5);
$member_obj->set('ShortDescription', $string);
$member_obj->insert($dbh);

$dbh->commit();

