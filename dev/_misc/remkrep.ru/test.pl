use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode 'encode';

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
	my $agent = LWP::UserAgent->new;
	my $url = "http://www.remkrep.ru/krepezh/ankery.html"; # the url to be tested
	
#	my $tree = HTML::TreeBuilder::XPath->new;
#	$tree->parse_content($agent->get($url)->decoded_content());
#
#	my @topnodes = $tree->findnodes( q{//ul[@id="nav"]/li} );
#	foreach my $tn (@topnodes){
#		my $ta = $tn->findnodes( q{a} )->[0];
#		my $name = encode('cp866', $ta->findvalue('.'));
#		$name =~ s/^ //;
#		print $name, "\n", $ta->findvalue('@href'), "\n";
#		
#		my @subnodes = $tn->findnodes( q{ul/li} );
#		foreach my $sn (@subnodes){
#			my $sa = $sn->findnodes( q{a} )->[0];
#			my $name = encode('cp866', $sa->findvalue('.'));
#			$name =~ s/^ //;
#			print "  ", $name, "\n", "  ", $sa->findvalue('@href'), "\n";
#		}
#	}
#	return;
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Category(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	#$test_obj->set('Level', 0); # 0 means the Root category
	#$test_obj->set('Page', 1);
	
	
	
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


