use strict;
use warnings;

use utf8;

use Error ':try';
use LWP::UserAgent;


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;

die "Already done";
#process_urls();

exit;


####################################################

sub process_urls {
	my $dbh = get_dbh();
	
	open LL, 'others.txt';
	my @links = <LL>;
	close LL;
	
	my $agent = LWP::UserAgent->new;
	
	foreach my $link (@links){
		chomp $link;
		#print "DDD $link\n";
		# get parent category
		if($link =~ /(.+\/)other\//){
			my $parent_link = $1;
			print "$1\n";
			
			# get parent category
			my $cat_obj = Category->new;
			$cat_obj->set('URL', $parent_link);
			$cat_obj->select($dbh);
			
			# check existence of OTHERS
			my $cat_others_obj = Category->new;
			$cat_others_obj->set('Category_ID', $cat_obj->ID);
			$cat_others_obj->set('Name', 'Прочие');
			unless($cat_others_obj->checkExistence($dbh)){
				print "No others, inserting into DB\n";
				$cat_others_obj->set('Status', 5);
				$cat_others_obj->set('URL', $parent_link.'other/');
				$cat_others_obj->set('Page', 1);
				$cat_others_obj->set('Level', $cat_obj->get('Level')+1);
				$cat_others_obj->insert($dbh);
				$dbh->commit();
			}
			
			# extract products from THE SPECIFIED vendor
			$cat_others_obj->set('URL', $link);
			my $request = $cat_others_obj->getRequest();
			my $response = $agent->request($request);
			if ($response->is_success()){
				try {
					$cat_others_obj->processResponse($dbh, $response, 0);
					$dbh->commit();
				} catch ISoft::Exception with {
					$dbh->rollback();
					print "Error: ", $@->message(), "\n", $@->trace();
				};
			}
			
		} else {
			die 'wtf';
		}
		
		
		
		
		
	}
	


	
	release_dbh($dbh);
}
