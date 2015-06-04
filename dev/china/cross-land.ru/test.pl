use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;

use Album;


test();


# ----------------------------

sub test {
	
	my $url = "http://cross-land.ru/19"; # the url to be tested
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Album(); # or another one...
	$test_obj->set('URL', $url);
	
	my $agent = LWP::UserAgent->new;
	my $request = $test_obj->getRequest();
	my $response = $agent->request($request);
	if ($response->is_success()){
		try {
			$test_obj->processResponse($dbh, $response, $debug);
		} catch ISoft::Exception with {
			print "Error: ", $@->message(), "\n", $@->trace();
		};
	}
	
	if(defined $dbh){
		release_dbh($dbh);
	}
	
}


