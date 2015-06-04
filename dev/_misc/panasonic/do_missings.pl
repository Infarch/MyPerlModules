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



process();


# ----------------------------

sub process {
	
	my $dbh = get_dbh();
	
	# get categories with products
	my $sql = "select ID from category c where c.Page=1 and exists (select * from product where category_ID=c.ID)";
	my @rows = ISoft::DB::do_query($dbh, sql=>$sql);
	
	# check each the category for the next page
	
	my $agent = LWP::UserAgent->new;
	
	foreach (@rows){
		my $id = $_->{ID};
		print "category $id\n";
		my $category_obj = Category->new;
		$category_obj->set("ID", $id);
		$category_obj->select($dbh);
		my $pn = $category_obj->get("Page");
		my $nextpage;
		do {
			my $request = $category_obj->getRequest();
			my $response = $agent->request($request);
			die "Failed" unless $response->is_success();
			my $tree = $category_obj->prepareContent($response);
			$nextpage = $category_obj->extractNextPage($tree);
			if($nextpage){
				print "Next page: $nextpage\n";
				$category_obj->set("URL", $nextpage);
				$category_obj->set("Page", ++$pn);
				$category_obj->update($dbh);
				# products ...
				print $category_obj->processProducts($dbh, $tree);
				print " products\n";
			}
			$tree->delete();
		} while ($nextpage);
		$dbh->commit() if $pn > 0;
		
		
	}
	
	
	release_dbh($dbh);
}


