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

use HTML::TreeBuilder::XPath;

test();


# ----------------------------

sub test {
	
	my $url = "http://www.100aromatov.ru/aromat/?id=3309"; # the url to be tested
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Product(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
#	$test_obj->set('Level', 0); # 0 means the Root category
#	$test_obj->set('Page', 1);
	
	
	my $agent = LWP::UserAgent->new;
	my $request = $test_obj->getRequest();
	my $response = $agent->request($request);
	
#	my $tree = HTML::TreeBuilder::XPath->new;
#	$tree->parse_content($response->decoded_content);
#	my @nodes = $tree->findnodes( q{//table/tr/td[3]/table/tr/td/table/tr/td[1]/img} );
#
#	print scalar @nodes;
#	
#	return;
	
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


