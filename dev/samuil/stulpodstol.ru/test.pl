use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DB;


use Category;
use Product;



test();


# ----------------------------

sub test {
	
	my $url = "http://www.stulpodstol.ru/catalog/wood-chairs/33692/"; # the url to be tested
	
	my $debug = 0;
	
	my $dbh = get_dbh() unless $debug;


	
	my $test_obj = new Product(); # or another one...
	$test_obj->set('ID', 2);
	$test_obj->select($dbh);
	
	#$test_obj->set('URL', $url);
	
	# for categories
	#$test_obj->set('Level', 0);
	#$test_obj->set('Page', 1);
	
	
	my $agent = LWP::UserAgent->new;
	my $request = $test_obj->getRequest();
	my $response = $agent->request($request);
	if ($response->is_success()){
		try {
			$test_obj->processResponse($dbh, $response, $debug);
		} catch ISoft::Exception with {
			print "Error: ", $@->longMessage(), "\n";
		} otherwise {
			print "$@\n";
		};
	}
	
	if(defined $dbh){
		$dbh->rollback(); # or commit
		$dbh->disconnect;
	}
	
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql(
		$constants{Database}{DB_Name},
		$constants{Database}{DB_User},
		$constants{Database}{DB_Password},
		$constants{Database}{DB_Host}
	);
}