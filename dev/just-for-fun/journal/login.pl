use strict;
use warnings;

use Digest::MD5 'md5_hex';
use WWW::Mechanize;


my $mech = WWW::Mechanize->new();

$mech->get('http://www.livejournal.com/');

my $content = $mech->content;

# get the 'login_chal' value
if ( $content !~ /id='login_chal'\svalue='(.*?)'/ ) {
	print "No login_chal value!";
	exit;
}

my $login_chal = $1;

my $username = 'infarch@ukr.net';
my $password = 'kx378rm512';

# calculate md5 hash of password
my $md5 = md5_hex($password);

my $identifier = md5_hex( $login_chal . $md5 );

$mech->submit_form(
	form_id => 'login',
	fields => {
		mode => 'login',
		chal => $login_chal,
		response => $identifier,
		user => $username,
		password => '',
		_submit => 'Log in',
	}
);

open PAGE, '>:encoding(UTF-8)', 'result.htm';
print PAGE $mech->content();
close PAGE;
