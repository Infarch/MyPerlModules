use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;

use Category;
use Product;



test();


# ----------------------------

sub testRoot{
	my $url = "http://www.panasonic.ru/support/download/manual/";
	my $agent = LWP::UserAgent->new;
	my $response = $agent->get($url);
	die "failed" unless $response->is_success();
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($response->decoded_content);
	
	# get suitable elements
	my @elements = $tree->findnodes( q{.//*[@id='maincol']/h2/span | .//*[@id='maincol']/div/table/tr/td/ul/li/a} );
	
	
	foreach my $element (@elements){
		
		if( $element->tag eq 'span' ){
			# top element
			my $name = $element->findvalue('.');
		} else {
			# child element
			my $name = $element->findvalue('.');
			my $href = $element->findvalue('./@href');
			print $href, "\n";
			
		}
		
		
		
	}
	
		
}

sub test {
	
	my $url = "http://www.panasonic.ru/support/download/manual/index.php?SECTION_ID=253&USECTION_ID=377"; # the url to be tested
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Category(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	$test_obj->set('Level', 0); # 0 means the Root category
	$test_obj->set('Page', 1);
	
	
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


