use strict;
use warnings;


use HTML::TreeBuilder::XPath;
use Image::Resize;
use GD::Image;


use DB_Member;
use DB_Item;
use DB_Rubric;
use DB_ItemRubric;

use lib ("/work/perl_lib");
use ISoft::DB;


#my $pictures = 'images/printsip';
#my $db = 'printsip';
#my $roottitle = 'Printsip.ru';

my $pictures = 'images/fluke';
my $db = 'fluke';
my $roottitle = 'Fluke-russia.ru';

my $isfluke = 1;




my $dbhs = ISoft::DB::get_dbh_mysql($db, 'root', 'admin');
my $dbhd = ISoft::DB::get_dbh_mysql('maxprofit', 'root', 'admin');

my $targetcat_obj = DB_Rubric->new;
$targetcat_obj->set('itemrub_title_ru', $roottitle);
$targetcat_obj->set('st', 1);
$targetcat_obj->insert($dbhd);

my $sourcecat_obj = DB_Member->new;
$sourcecat_obj->set('Member_ID', undef);
$sourcecat_obj->select($dbhs);

process_category($dbhs, $sourcecat_obj, $dbhd, $targetcat_obj);


$dbhd->commit();
$dbhs->rollback();

print "Done\n";


sub process_category {
	my ($dbhs, $sourcecat_obj, $dbhd, $targetcat_obj) = @_;

	print $sourcecat_obj->ID, "\n";

	# process products
	my $pmember_obj = DB_Member->new;
	$pmember_obj->set('Member_ID', $sourcecat_obj->ID);
	$pmember_obj->set('Type', $DB_Member::TYPE_PRODUCT);

	$pmember_obj->set('Vendor', 'Fluke')->setOperator('Vendor', '!=') if !$isfluke;
	
	my @products = $pmember_obj->listSelect($dbhs);

	foreach my $product(@products){

		my $obj = DB_Item->new();
		$obj->set('item_title_ru', $product->Name);
		
		my $descr = $product->get('FullDescription');
		
		
		
		if ($isfluke){
			
			my $tree = HTML::TreeBuilder::XPath->new;
			$tree->parse_content($descr);
			my @pictures = $tree->findnodes( q{//img} );
			foreach my $picture (@pictures){
				# check existence of picture
				my $tmp_obj = DB_Member->new;
				$tmp_obj->set('ID', $picture->attr('member'));
				if($tmp_obj->checkExistence($dbhs)){
					
					my $name = $tmp_obj->Name;
					$picture->attr('src', "/images/userfiles/$name");
					$picture->attr('member', '');
					
				} else {
					# no picture!!!!
					$picture->delete();
				}
			}
			
			$descr = $tree->as_HTML('<>&');
			
		}
		
		$obj->set('item_body_ru', $descr);
		
		$obj->set('item_anonce_ru', $product->get('ShortDescription'));


		my $xx = $product->get('Price');
		$obj->set('item_price', $xx);
		$obj->set('st', 1);

		$obj->insert($dbhd);


		# photo processor!!!!!

		my $photo_obj = DB_Member->new;
		$photo_obj->set('Member_ID', $product->ID);
		$photo_obj->set('Type', $DB_Member::TYPE_PICTURE);
		if ($photo_obj->checkExistence($dbhs)){

			my $id = $obj->ID;

			# create directory
			my $dir = 'images_converted/'.$id;
			mkdir $dir;

			# copy original
			my $image = Image::Resize->new($pictures.'/'.$photo_obj->Name);
			my $gd = $image->gd();
			open IMG, ">$dir/org.gif";
			binmode IMG;
			print IMG $gd->gif();
			close IMG;

			my ($width, $height) = $gd->getBounds();


			my $resized = $gd;
			# resize to 200x200
			my $small = 'small.gif';
			if($width>200 || $height>200){
				$resized = $image->resize(200, 200);
			}
			open IMG, ">$dir/$small";
			binmode IMG;
			print IMG $resized->gif();
			close IMG;


			$resized = $gd;
			# resize to 350x350
			my $large = 'large.gif';
			if($width>350 || $height>350){
				$resized = $image->resize(350, 350);
			}
			open IMG, ">$dir/$large";
			binmode IMG;
			print IMG $resized->gif();
			close IMG;


			$obj->set('item_photo', "/images/catalog/$id/$small");
			$obj->set('item_photo_big', "/images/catalog/$id/$large");

			$obj->update($dbhd);
		}



		my $link_obj = DB_ItemRubric->new;
		$link_obj->set('item_id', $obj->ID);
		$link_obj->set('itemrub_id', $targetcat_obj->ID);

		$link_obj->insert($dbhd);

	}


	# process sub categories using the same function

	my $cmember_obj = DB_Member->new;
	$cmember_obj->set('Member_ID', $sourcecat_obj->ID);
	$cmember_obj->set('Type', $DB_Member::TYPE_CATEGORY);

	my @categories = $cmember_obj->listSelect($dbhs);

	foreach my $category (@categories){

		my $obj = DB_Rubric->new;
		$obj->set('itemrub_pid', $targetcat_obj->ID);
		$obj->set('itemrub_title_ru', $category->Name);
		$obj->set('st', 1);
		$obj->insert($dbhd);

		process_category($dbhs, $category, $dbhd, $obj);


	}


}
