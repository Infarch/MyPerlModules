use strict;
use warnings;
use utf8;

#use open qw(:std :utf8);

use Encode qw /decode encode/;
use Error qw(:try);
use Data::Dumper;
use File::Copy;
use GD::Image;
use HTML::TreeBuilder::XPath;
use Image::Resize;




use lib ("/work/perl_lib");
use ISoft::Conf;
use ISoft::DB;

use DB_Member;

my @vendors = (

	'AD','ALCA','Alligator', 'Alpine','AMD','Art Sound','ASUS','ATOMY','Audio System','Audiovox','Audison',
	'Auditor','Autofun','Autotek','Beyma','Bigson','Blaupunkt','BOSCH','Boschmann','Boston Acoustic..',
	'Brax','Bull Audio','Calearo','CDD','CDT Audio','Celestra','Celsior','Challenger','Clarion','Cobra',
	'COIDO','Crunch','CTEK','Daxx','DD Audio','DLS','E.O.S.','EDGE','Eton','FLI','Focal','Garmin','Genesis',
	'GoClever','Ground Zero','Helix','Hertz','ICON','Infinity','Instal Service','Intel','IXI','Jaguar','JBL',
	'JVC','Kenwood','KGB','Kicker','Kicx','Lanzar','Longhorn','MacAudio','Macrom','Magnat','MB Quart','MLux',
	'Mongoose','Morel','Multitronics','MyCar','Mystery','NaviTop','NEC','nTray','ORION','Oris Electronic..',
	'Panasonic','Pantera','Parrot','Phantom','Philips','Phoenix Gold','Pioneer','PolkAudio','Power Acoustik',
	'Premiera','Prolight','Prology','Rainbow','REVOLT by Audio..','Scher-Khan','SHERIFF','Signat','Sony',
	'Soundstream','SPL','SPL-Laboratory','Star','StarLine','Steg','Supra','Tenex','Treefrog','United','Varta',
	'Velas','Vibe','Videovox','Vitol','WEG','Whistler','X-Driven','XM','Yurson','Компопласт','[OEM]','µ-Dimension',
	
);


# get database handler
my $dbh = get_dbh();

#load categories
my $cat_obj = DB_Member->new;
$cat_obj->Type($DB_Member::TYPE_CATEGORY);


#my %categories = map { $_->ID => encode('cp866', $_->Name) } $cat_obj->listSelect($dbh);

my %categories = map { $_->ID => $_ } $cat_obj->listSelect($dbh);

#print Dumper(\%categories);


# load products
my $prod_obj = DB_Member->new;
$prod_obj->Type($DB_Member::TYPE_PRODUCT);
#$prod_obj->set('ID', 4037);
my @prod_list = $prod_obj->listSelect($dbh);


print "Started creating CSV...\n";

make_csv($dbh, \@prod_list, \%categories, 'output.csv');







$dbh->rollback();
$dbh->disconnect();

exit;


#################### functions ###########################

sub shopos_provider {

	my $data_ref = shift;
	
	# columns definition - ShopOS CSV format (brief, only for adding)
	my @all_columns = (
		{ title=>'v_products_id', mapto=>'none', default=>'0'},
		{ title=>'v_products_model', mapto=>'article'}, #***
		{ title=>'v_products_image', mapto=>'image'}, #***
		{ title=>'v_products_name_1', mapto=>'name'}, #***
		{ title=>'v_products_description_1', mapto=>'description_full'}, #***
		{ title=>'v_products_price', mapto=>'price', default=>'0.01'}, #***
		{ title=>'v_products_weight', mapto=>'none', default=>'0'},
		{ title=>'v_date_added', mapto=>'none', default=>'2.12.2010 18:00'},
		{ title=>'v_products_quantity', mapto=>'none', default=>'0'},
		{ title=>'v_products_sort', mapto=>'none', default=>'0'},
		{ title=>'v_manufacturers_name', mapto=>'vendor'}, #***
		{ title=>'v_categories_name_1', mapto=>'category1'}, #***
		{ title=>'v_categories_name_2', mapto=>'category2'}, #***
		{ title=>'v_categories_name_3', mapto=>'category3'}, #***
		{ title=>'v_categories_name_4', mapto=>'category4'}, #***
		{ title=>'v_categories_name_5', mapto=>'category5'}, #***
		{ title=>'v_categories_name_6', mapto=>'category6'}, #***
		{ title=>'v_categories_name_7', mapto=>'category7'}, #***
		{ title=>'v_tax_class_title', mapto=>'none', default=>'--нет--'},
		{ title=>'v_status', mapto=>'none', default=>'Active'},
		{ title=>'EOREOR', mapto=>'none', default=>'EOREOR'},
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	foreach my $column (@all_columns){
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
		push @defaults, exists $column->{default} ? $column->{default} : '';
	}
	my $glue_char = "\t";
	my @output;
	# make header
	push @output, join ($glue_char, @header_list);
	# process data
	my $col_number = @map_list;
	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my $suppress_defaults = $dataitem->{suppress_defaults};
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = (exists $dataitem->{$key} && $dataitem->{$key}) ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			if ($value =~ /$glue_char/o){
				$value = '"' . $value . '"';
			}
			if ( $value =~ /"$/ ) #"
			{
				$value .= ' ';
			}
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	return \@output;
}


sub make_csv {
	my ($dbh, $data_ref, $categories_ref, $filename) = @_;
	
	my $files = $constants{General}{Files_Directory};
	
	# prepare folders
	my $pictures = 'output_pictures';
	my $pic_org = 'original_images';
	my $pic_popup = 'popup_images';
	my $pic_thumb = 'thumbnail_images';
	my $pic_info = 'info_images';
	
	my $pic_article = 'supplementary';
	
	if (!-e $pictures || !-d $pictures){
		mkdir $pictures or die $!;
	}

	if (!-e "$pictures/$pic_org" || !-d "$pictures/$pic_org"){
		mkdir "$pictures/$pic_org" or die $!;
	}

	if (!-e "$pictures/$pic_popup" || !-d "$pictures/$pic_popup"){
		mkdir "$pictures/$pic_popup" or die $!;
	}

	if (!-e "$pictures/$pic_thumb" || !-d "$pictures/$pic_thumb"){
		mkdir "$pictures/$pic_thumb" or die $!;
	}

	if (!-e "$pictures/$pic_info" || !-d "$pictures/$pic_info"){
		mkdir "$pictures/$pic_info" or die $!;
	}
	
	if (!-e "$pictures/$pic_article" || !-d "$pictures/$pic_article"){
		mkdir "$pictures/$pic_article" or die $!;
	}

	my $count = 0;
	
	my @result_list;
	
	foreach my $item (@$data_ref){
		
#		last if $count++ > 4;

		my %result;
				
		my $id = $item->ID;
		
		# article
		$result{article} = $item->get('InternalID');
		
		# pictupe
		my $pic_obj = DB_Member->new;
		$pic_obj->Member_ID($id);
		$pic_obj->Type($DB_Member::TYPE_PICTURE);
		$pic_obj->Status($DB_Member::STATUS_DONE);
		if($pic_obj->checkExistence($dbh)){
			# do resize if necessary
			my $picnamefull = $pic_obj->Name;
			$picnamefull =~ /^(.+?)\./;
			my $new_picnamefull = "$1.gif";
			unless (-e "$pictures/$pic_org/$new_picnamefull"){
				# resizing
				my $pid = $pic_obj->ID;
				
				my $full = 1;
				
				if($full){
					my $image = Image::Resize->new("$files/$pid");
					# save original
					my $gd_org = $image->gd();
					open (ORG, ">$pictures/$pic_org/$new_picnamefull") or die "Cannot open image file: $!";
					binmode ORG;
					print ORG $gd_org->gif();
					close ORG;
	
					my $width = $image->width();
					my $height = $image->height();
					
					# thumbnail 170 x 130
					if($width>170 || $height>130){
						my $tgd = $image->resize(170, 130);
						open (TH, ">$pictures/$pic_thumb/$new_picnamefull") or die "Cannot open image file: $!";
						binmode TH;
						print TH $tgd->gif();
						close TH;
					} else {
						open (TH, ">$pictures/$pic_thumb/$new_picnamefull") or die "Cannot open image file: $!";
						binmode TH;
						print TH $gd_org->gif();
						close TH;
					}
					
					# info 270 x 210
					if($width>270 || $height>210){
						my $igd = $image->resize(270, 210);
						open (INF, ">$pictures/$pic_info/$new_picnamefull") or die "Cannot open image file: $!";
						binmode INF;
						print INF $igd->gif();
						close INF;
					} else {
						open (INF, ">$pictures/$pic_info/$new_picnamefull") or die "Cannot open image file: $!";
						binmode INF;
						print INF $gd_org->gif();
						close INF;
					}
					
					# popup 600 x 480
					if($width>600 || $height>480){
						my $pgd = $image->resize(600, 480);
						open (PP, ">$pictures/$pic_popup/$new_picnamefull") or die "Cannot open image file: $!";
						binmode PP;
						print PP $pgd->gif();
						close PP;
					} else {
						open (PP, ">$pictures/$pic_popup/$new_picnamefull") or die "Cannot open image file: $!";
						binmode PP;
						print PP $gd_org->gif();
						close PP;
					}
					
				} else {
					copy("$files/$pid", "$pictures/$pic_org/$new_picnamefull");
				}
				
				
			}
			$result{image} = $new_picnamefull;
			
			# picture done
		}
		
		my $name = $item->Name;
		my $groupname = $item->get('GroupName');
		
		# Name
		$result{name} = "$groupname $name";
		
		# description (including pictures)
		if(my $description = $item->get('Description')){
			
			my $tree = HTML::TreeBuilder::XPath->new;
			$tree->parse_content("<html><head><title>1</title></head><body><span id='contentholder'>$description</span></body></html");
			my @picnodes = $tree->findnodes( q{//img} );
			foreach my $node (@picnodes){
				my $pm_id = $node->attr('member');
				
				my $pic_member_obj = DB_Member->new;
				$pic_member_obj->set('ID', $pm_id);
				if($pic_member_obj->checkExistence($dbh)){
					# update url
					my $ap_url = $pic_member_obj->URL;
					$ap_url =~ /\/([^\/]+)$/;
					my $ap_name = "$pictures/$pic_article/$1";
					$ap_url = "/images/$pic_article/$1";
					
					# update url
					$node->attr('src', $ap_url);
					
					# copy the picture
					copy("$files/$pm_id", $ap_name);
					
				} else {
					print "No artile picture!\n";
				}
				$node->attr('member', undef);
			}
		
			my @cnodes = $tree->findnodes( q{/html/body/span[@id='contentholder']/*} );
			$description = '';
			foreach (@cnodes){
				$description .= $_->as_HTML('<>&', ' ', {});
			}
			$description =~ s/\r|\n|\t/ /g;
			$description =~ s/\s{2,}/ /g;
		
			$tree->delete();
			
			$result{description_full} = $description;
		}
		
		
		# price
		$result{price} = int($item->get('Price')*31.3518);
		
		# vendor
		foreach my $xv (@vendors){
			# look for the vendor
			if($name=~/\b$xv\b/){
				$result{vendor} = $xv;
				last;
			}
		}
		
		# categories
		my $cc = 1;
		my @clist = catlist($item->Member_ID, $categories_ref);
		while(defined(my $cname = shift @clist)){
			$result{"category$cc"} = $cname;
			$cc++;
		}
		
		push @result_list, \%result;
	}
	
	open CSV, '>:encoding(UTF-8)', $filename;
	my $result_ref = shopos_provider(\@result_list);
	foreach my $line (@$result_ref){
		print CSV $line . chr(10);
	}

	close CSV;
	
}

sub catlist {
	my ($id, $catref) = @_;
	
	my @list;
	my $cat;
	do{
		$cat = $catref->{$id};
		my $name = $cat->Name;
		$name =~ s/^\s+//;
		$name =~ s/\s+$//;
		unshift @list, $name;
		$id = $cat->Member_ID;
	} while ( defined $id );
	shift @list;
	
	#unshift @list, 'TEST';
	
	return @list;
}

sub get_dbh {
	my $db_name = $constants{Database}{DB_Name};
	my $db_user = $constants{Database}{DB_User};
	my $db_pass = $constants{Database}{DB_Pass};

	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass);
}


