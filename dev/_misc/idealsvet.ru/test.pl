use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;

use Category;
use Product;



test();


# ----------------------------

sub test {
	
	my $debug = 1; # debug mode on
	my $dbh = get_dbh() unless $debug;
	
	my $url = "http://idealsvet.ru/catalog/2259_seriya_SL107/9509_Bra_ST_Luce_SL107_301_01/"; # the url to be tested
	
	my $test_obj = new Product(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	#$test_obj->set('Level', 2); # 0 means the Root category
	#$test_obj->set('Page', 1);
	
	
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
		$dbh->release_dbh(); # or commit
	}
	
}


