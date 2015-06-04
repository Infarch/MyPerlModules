use strict;
use warnings;

use Error ':try';
use Encode qw/encode decode/;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use Image::Resize;





use lib ("/work/perl_lib");
use ISoft::DB;
use ISoft::Exception;
use ISoft::Exception::ScriptError;


use CategoryCorr;
use CategoryPicture;

use ISoft::ParseEngine::ThreadProcessor;

test();

# -----------------------------------------------------------------------

sub test {
	
	my $agent = LWP::UserAgent->new;
	
	my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
	my $dbh = $tp->getDbh();

	my @catlist = CategoryCorr->new->selectAll($dbh);
	
	my %cat_hash = map { $_->ID => $_ } @catlist;
	
	my %affected;
	
	foreach my $category (@catlist){
		# skip the root directory
		next unless defined $category->get('Category_ID');
		
		# get parent
		my $parentcategory = $cat_hash{$category->get('Category_ID')};
		# may be already done?
		my $parent_id = $parentcategory->ID;
		next if exists $affected{$parent_id};
		
		$affected{$parent_id} = 1;
		print "Checking $parent_id\n";
		
		# fetch subcategories info
		my $request = $parentcategory->getRequest();
		my $resp = $agent->request($request);
		die "Failed" unless $resp->is_success();
		
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($resp->decoded_content());
		my $data = $parentcategory->extractSubCategoriesData($tree);
		
		# update category pictures
		foreach my $dataitem (@$data){
			# get a subcategory
			my $subobj = CategoryCorr->new;
			$subobj->set('Category_ID', $parent_id);
			$subobj->set('Name', $dataitem->{Name});
			$subobj->select($dbh);
			
			# get picture
			my $catpic_obj = $subobj->getPicture($dbh);
			my $pic_url = $catpic_obj->get('URL');
			if($dataitem->{Picture} ne $pic_url){
				print "Bad picture ", $catpic_obj->ID, ", updating...\n";
				$catpic_obj->set('URL', $dataitem->{Picture});
				my $r1 = $catpic_obj->getRequest();
				my $rs1 = $agent->request($r1);
				die "Failed" unless $rs1->is_success();
				
				$catpic_obj->processResponse($dbh, $rs1);
				
			}
			
		}
		
	}







	$dbh->commit();
	$dbh->disconnect();
	

}

