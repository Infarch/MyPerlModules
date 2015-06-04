use strict;
use warnings;

use utf8;

use Error ':try';
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use URI;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DB;


use Category;
use Product;



test();


# ----------------------------

sub mkroot {
	
	my $obj = new Category();
	$obj->set('URL', $constants{Parser}{Root_Category});
	
	my $agent = LWP::UserAgent->new;
	my $content = $agent->get($constants{Parser}{Root_Category})->decoded_content();
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	
	my @toplist = grep { $_->attr('onclick') =~ /collapseBlock\(\d+\)/ } $tree->findnodes( q{//a[@onclick]} );
	
	foreach my $topitem (@toplist){
		$obj->debugEcho($topitem->as_text());
		
		my $onc = $topitem->attr('onclick');
		$onc =~ /collapseBlock\((\d+)\)/;
		my $num = $1;
		
		my @sublist = $tree->findnodes( qq{//div[\@id='block$num']/a[\@class='catlink']} );
		
		foreach my $subitem (@sublist){
			
			my $name = $subitem->as_text();
			
			next if $name =~ /все позиции/;
			
			my $href = $subitem->attr('href');
			$href =~ s/^\.\.//;
			$href = $obj->absoluteUrl($href);
			
			$obj->debugEcho("  $name ($href)");
		}
		
	}
	
}

sub test {
	
	my $url = "http://www.premierdecor.ru/catalogue/index.php?n=2152"; # the url to be tested
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Product(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	#$test_obj->set('Level', 2);
	#$test_obj->set('Page', 1);
	
	
	my $agent = LWP::UserAgent->new;
	my $request = $test_obj->getRequest();
	my $response = $agent->request($request);
	if ($response->is_success()){
		$test_obj->processResponse($dbh, $response, $debug);
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