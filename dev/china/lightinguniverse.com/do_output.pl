use strict;
use warnings;

use utf8;

use File::Copy;
use File::Path;
use Encode qw/encode decode/;
use Storable qw(freeze thaw);

use HTTP::Response;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;
use Option;
use OptionValue;
use Property;
use ProductPicture;
use ExportUtils;
use Feature;

our $output = 'z:/P_FILES/lightinguniverse/output';
unless (-e $output && -d $output){
	mkpath($output);
}

our %cat_cache;
our %feature_cache;
our %option_cache; # ID => Name
our %stop_registry; # product codes from the registry will not be processed
our @chars = qw(A B C D E F G H J K L M N P R T U V W Y);

our %canfilter = (
	$Feature::TYPE_CHECKBOX_MULTIPLE => 1,
	$Feature::TYPE_OTHER_DATE => 1,
	$Feature::TYPE_OTHER_NUMBER => 1,
	$Feature::TYPE_OTHER_RANGE => 1,
	$Feature::TYPE_SELECT_NUMBER => 1,
	$Feature::TYPE_SELECT_TEXT => 1
);

our @sql;
our @collector;
our @images;

# page cache
our $cached_content;
our $cached_key = '';

# SERVICE OPERATIONS

#update_prods();
#improve_listing();

# OUTPUT

# set 0 to avoid limitation
our $vendor_limit = 0;
our $prod_limit = 0;

my $start = time;
#init_features_filters();
cache_features();
init_options();
process_vendors();
my $stop = time;

print "Operation took ", $stop-$start, " seconds\n";

exit;

# --------------------------------------------------

sub init_options {
	my $dbh = get_dbh();
	my @list = Option->new()->selectAll($dbh);
	%option_cache = map { $_->ID => $_->get("Name") } @list;
	release_dbh($dbh);
}

sub update_prods {
	my $dbh = get_dbh();
	
	my @vendors = ISoft::DB::do_query($dbh, sql=>"select distinct Vendor from product");
	foreach (@vendors){
		my $v = $_->{Vendor};
		
		# get products
		my $prod = Product->new;
		$prod->set('Vendor', $v);
		$prod->set('Processed', 0);
		$prod->markDone();
		
		my @plist = $prod->listSelect($dbh);
		
		print "$v - ", scalar @plist, "\n";
		
		foreach $prod (@plist){
			my $pid = $prod->ID;
			
			#get_style($dbh, $prod);
			#get_list_price($dbh, $prod);
			#get_free_shipping($dbh, $prod);
			#get_description($dbh, $prod);
			#get_instock($dbh, $prod);
			#$prod->set('DestinationCode', mkcode($pid));
			
			get_max_price($dbh, $prod);
			
			$prod->set('Processed', 1);
			# update
			$prod->update($dbh);
			$dbh->commit();
		}
		
	}
	release_dbh($dbh);
}

# the function tries to search product images. but it seems that it utilises modern page format while
# cached pages are old-styled. it might be useful in the future, however...
sub check_images {
	my $dbh = get_dbh();
	
	print "\n\n\n";
	
	my $p = Product->new;
	$p->markDone();
	$p->maxReturn(20);
	my @plist = $p->listSelect($dbh);
	foreach my $prod (@plist){
		
		my $pid = $prod->ID;
		
		my $content = get_cached_page($dbh, $prod->getMD5());
		unless($content){
			print "No content $pid\n";
			next;
		}
		
		# look for images
		my @parts = $content=~/arrAltImg\[\d+\]=\{(.*?)\}/g;
		
		my @pics;
		
		foreach my $part (@parts){
			print "PART: ", $part, "\n";
			if($part=~/image:'(.*?)'/){
				my $img = $1;
				if($part=~/hasImgXL:1/){
					$img =~ s/img\/t\//\/img\/x\//;
				} elsif($part=~/hasImgLarge:1/){
					$img =~ s/img\/t\//\/img\/l\//;
				}else{
					$img =~ s/img\/t\//\/img\/p400\//;
				}
				push @pics, $img;
				
			}
			
		}
		
		if(@pics==0){
		my ($extra) = $content =~ /var defPath="(.*?)"/;
			if($extra){
				$extra =~ s/^\/\//http:\/\//;
			}
			push @pics, $extra;
		}
		
		print "----------- $pid ---------------\n";
		print "$_\n" foreach @pics;
		
	}
	
	
	
	
	release_dbh($dbh);
}

sub update_sharing {
	my $dbh = get_dbh();
	my @scripts;
	# check features
	my @flist = Feature->new()->selectAll($dbh);
	foreach my $feature (@flist) {
		my $fid = $feature->get('CartID');
		# check the damned object
		my($row1) = ISoft::DB::do_query($dbh, sql=>"select * from `cscart_ult_objects_sharing` where `share_object_id`=? and `share_object_type`=?", values=>[$fid, 'product_features']);
		unless(defined $row1){
			push @scripts, "insert into `cscart_ult_objects_sharing` (`share_company_id`,`share_object_id`,`share_object_type`) values (1,'$fid','product_features')";
		}
	}
	# check filters
	my @filters = ISoft::DB::do_query($dbh, sql=>'select * from `cscart_product_filters`');
	foreach my $filter (@filters) {
		my $fid = $filter->{filter_id};
		# check the damned object
		my($row1) = ISoft::DB::do_query($dbh, sql=>"select * from `cscart_ult_objects_sharing` where `share_object_id`=? and `share_object_type`=?", values=>[$fid, 'product_filters']);
		unless(defined $row1){
			push @scripts, "insert into `cscart_ult_objects_sharing` (`share_company_id`,`share_object_id`,`share_object_type`) values (1,'$fid','product_filters')";
		}
	}
	if(@scripts>0){
		open XX, '>update-script.sql';
		print XX "$_;\n" foreach @scripts;
		close XX;
	}
	release_dbh($dbh);
}

sub improve_listing {
	my $dbh = get_dbh();

	my %known = (
		'Quick Ship' => 0,
		'Mfr Specials' => 0,
		'Energy Saving' => 0,
		'Eco-Friendly' => 'Eco Friendly',
		'ADA' => 0,
		'Duty Free In Canada' => 0,
		'Made in the USA' => 0,
		'Made In Europe' => 0,
		'Eco Friendly' => 0,
		'CUL Listed' => 0,
		'Featured Product' => 0,
		'ETL Listed' => 0,
		'Low Voltage' => 0,
		'LED' => 0,
		'C.U.L. Listed' => 'CUL Listed',
		'Dark Sky' => 0,
		'CSA America' => 0,
		'AGA Listed' => 0,
		'EPA' => 0,
		'Intertek' => 0,
		'NEO-C' => 0,
	);

	my @items = ISoft::DB::do_query($dbh, sql=>'select * from `property` where `name`=? and `state`=?', values=>['Listing', 0]);
	# apply filter
	foreach my $row (@items){
		my $id = $row->{ID};
		my $val = $row->{Value};
		
		my @parts;
		foreach (split ',', $val){
			my $part = trim($_);
			if($part ne ''){
				if(exists $known{$part}){
					# do we need to replace the part?
					$part = $known{$part} if $known{$part};
					push @parts, $part;
				} else {
					# add to fail list;
					#push @failparts, $part;
					
					print "Unknown item $val\n";
					
				}
			}
		}
		if(@parts>0){
			my $str = join '-!-', @parts;
			ISoft::DB::do_query($dbh, sql=>"update `property` set newValue=?, state=? where id=?", values=>[$str, 1, $id]);
			$dbh->commit();			
		}
		
	}

	release_dbh($dbh);
}

sub trim {
	my $v = shift;
	$v =~ s/^\s+//;
	$v =~ s/\s+$//;
	return $v;
}

# loads all features from db to cache
sub cache_features {
	my $dbh = get_dbh();
	
	my @features = Feature->new->selectAll($dbh);
	print "Total features: ", scalar @features;
	print "\n";
	
	foreach my $feature (@features){
		my $name = $feature->get("Name");
		
		unless(exists $feature_cache{$name}){
			$feature_cache{$name} = $feature;
			next;
		}
		print "$name exists\n";
		# the feature already exists. the main rule is that multiple selection features must be overriden
		if($feature_cache{$name}->get("Type") eq $Feature::TYPE_CHECKBOX_MULTIPLE){
			die "Two multiple features" if $feature->get("Type") eq $Feature::TYPE_CHECKBOX_MULTIPLE;
			print $feature->get("Type"), " overrides M in $name\n";
			$feature_cache{$name} = $feature;
		}
	}
	
	print "Now we have ", scalar keys %feature_cache;
	print " features\n";
	
	
	release_dbh($dbh);
}

# loads all features from db to cache, inserts them when do not exist, creates filters, etc.
sub init_features_filters {
	my $dbh = get_dbh();
	
	my $fobj = Feature->new;
	$fobj->prepareEnvironment($dbh);
	$dbh->commit();
	
	my @need_filter = qw(
		GlassType Team InstallPosition NumberofBlades Listing ArmLength ShadeMaterial Type BladeSpan Diameter Height
		TeamSchool LampType Material NumberofLights Width ShadeColor Projection ShadeShape OverallHeight BodyHeight Application
		Lighting BladePitch Finish Remote Style AirVolume OverallLength LightKit Voltage Materials Brand ProductStyle
	);
	
	my %nf = map { $_ => 1 } @need_filter;
	
	my %filter_ranges = (
		NumberofBlades => [[1,1],[2,2],[3,3],[4,4],[5]],
		ArmLength => [[1,5],[6,10],[11,15],[16,20],[21]],
		Projection => [[1,200],[201,400],[401,600],[600,800],[801,1000],[1001]],
		OverallHeight => [[1,100],[101,200],[201,300],[301,400],[401]],
		BodyHeight => [[1,20],[21,40],[41,60],[61,80],[81,100],[101]],
		OverallLength => [[1,20],[21,40],[41,60],[61]]
	);
	
	my @scripts;
	
	# get ALL feature names
	my @features = ISoft::DB::do_query($dbh, sql=>"select * from `names`");
	
	# add Brand and ProductStyle as features
	push @features, {
		name => 'Brand',
		type => 'string',
		multiSelect => 0
	};
	
	push @features, {
		name => 'ProductStyle',
		type => 'string',
		multiSelect => 0
	};

	push @features, {
		name => 'Collection',
		type => 'string',
		multiSelect => 0
	};

	push @features, {
		name => 'MaximumPrice',
		type => 'real',
		multiSelect => 0
	};

	push @features, {
		name => 'Returnable',
		type => 'checkbox',
		multiSelect => 0
	};

	foreach my $feature (@features){
		my $fname = $feature->{name};
		next if $fname eq 'Price';
		# check existence of the feature
		my $feature_obj = Feature->new();
		$feature_obj->set('Name', ExportUtils::get_property_name($fname));
		$feature_obj->set('Type', Feature::get_feature_type($feature->{type}, $feature->{multiSelect}));
		
		# KOSTYL!!!
		$feature_obj->{type} = $feature->{type};
		
		if($feature_obj->checkExistence($dbh)){
			$feature_cache{$fname} = $feature_obj;
			print "$fname - exists\n";
			next;
		}
		print "$fname - inserting\n";
		# no feature, insert
		$feature_obj->set('Suffix', $feature->{units} ? ' '.$feature->{units} : '');
		$feature_obj->set('Prefix', '');
		$feature_obj->csInsertFeature($dbh, \@scripts);
		$feature_obj->insert($dbh);
		$feature_cache{$fname} = $feature_obj;
		# make filters
		if($nf{$fname}){
			my $filter_id = $feature_obj->csInsertFilter($dbh, \@scripts);
			# ranged?
			my $rdata = $filter_ranges{$fname};
			if(defined $rdata){
				my $position = 0;
				foreach my $range (@$rdata){
					# insert range
					my($from, $to) = @$range;
					$feature_obj->csCreateFilterRange($dbh, $filter_id, $from, $to, $position++, \@scripts);
				}
			}
		}
		$dbh->commit();
	}
	
	release_dbh($dbh);
	
	if(@scripts > 0){
		open XX, ">$output/scripts.sql";
		print XX "$_\n" foreach @scripts;
		close XX;
		
		print "\nNew script file has been created\n"
	}
	
}

sub is_feature_multiple {
	my ($fname) = @_;
	return $feature_cache{$fname}->get('Type') eq $Feature::TYPE_CHECKBOX_MULTIPLE;
}

sub is_feature_range {
	my ($fname) = @_;
	return $feature_cache{$fname}->get('Type') eq $Feature::TYPE_OTHER_RANGE;
}

sub process_vendors {
	my $dbh = get_dbh();

	my @vendors = ISoft::DB::do_query($dbh, sql=>"select distinct Vendor from product");

	my $vl = $vendor_limit;
	
	foreach my $vendor (@vendors){
		process_vendor($dbh, $vendor->{Vendor});
		if($vendor_limit){
			last unless --$vl;
		}
	}

	release_dbh($dbh);
	
	save_csv_parts(\@collector, \&columns_product, 10000, 'products');
	save_csv_parts(\@images, \&columns_files, 10000, 'images');
	
}

sub save_csv_parts {
	my ($data, $columns, $pagesize, $name) = @_;
	
	my $from = 0;
	my $size = @$data;
	my $count = 1;
	
	while ($from < $size){
		my $to = $from + $pagesize;
		$to = $size-1 if($to > $size-1);
		
		my @part = @$data[$from..$to];
		
		save_csv("$output/$name.$count.csv", \@part, $columns);
		$count++;
		$from = $to + 1;
	}		
	
}

sub process_vendor {
	my ($dbh, $vendor) = @_;

	print $vendor, "\n";

	# make it safe
	my $vsafe = $vendor;
	$vsafe =~ s#[^a-zA-Z0-9\-]#-#g;
	# create folder
	my $output_vendor_images = $output . "/images/" . $vsafe;
	my $output_vendor_manuals = $output . "/manuals/" . $vsafe;
	unless (-e $output_vendor_images && -d $output_vendor_images){
		mkpath($output_vendor_images) or die "$!";
	}
	unless (-e $output_vendor_manuals && -d $output_vendor_manuals){
		mkpath($output_vendor_manuals) or die "$!";
	}

	# process products
	my $prod_obj = Product->new;
	$prod_obj->set('Vendor', $vendor);
	$prod_obj->markDone();
	$prod_obj->maxReturn($prod_limit) if $prod_limit;
	my $prod_list = $prod_obj->listSelect($dbh);
	print scalar @$prod_list, " products\n";

	# I will save all vendors and images regardless of vendor

	process_product($dbh, $_, \@collector, \@images, $output_vendor_images, $output_vendor_manuals, $vendor, $vsafe) foreach @$prod_list;

}

sub process_product {
	my ($dbh, $prod_obj, $collector, $imagescollector, $output_vendor_images, $output_vendor_manuals, $vendor, $vsafe) = @_;

	my $pid = $prod_obj->ID;
	print "$pid\n";

	my $code = $prod_obj->get('DestinationCode');
	
	my $intId = $prod_obj->get('InternalID');
	return if exists $stop_registry{$intId};
	$stop_registry{$intId} = 1;

	# my $catname = get_cat_path($dbh, $prod_obj->get('Category_ID'));
	
	# new structure: BY BRAND//$brand///$collection///$product
	my $catname = "By brand///$vendor";
	if(my $collection = $prod_obj->get('Collection')){
		$catname .= '///' . $collection;
	}
	$catname =~ s/&amp;/&/ig;
	# RESTRICTION!!!
	die "Restricted character in $catname" if $catname=~/;/;


	my $item = {
		category => $catname,
		name => $prod_obj->get('Name'),
		code => $code,
		feature_comparison => 'Y',
		store => 'www.lights-depot.com',
		factory_number => $intId,
	};

	my @options;
	my %features;
	
	# get other products with the same code - they are only reflections
	my $tmp_prod_obj = Product->new;
	$tmp_prod_obj->markDone();
	$tmp_prod_obj->set('InternalID', $intId);
	$tmp_prod_obj->set('ID', $pid);
	$tmp_prod_obj->setOperator('ID', '!=');
	my @reflections = $tmp_prod_obj->listSelect($dbh);
	my @clist = map { get_cat_path($dbh, $_->get('Category_ID')) } @reflections;
	
	# add also the current product's category
	push @clist, get_cat_path($dbh, $prod_obj->get('Category_ID'));
	
	$item->{secondary_categories} = join ';', @clist if @clist > 0;

	my $description = '';
	if($vendor ne 'unknown'){
		$features{Brand} = $vendor;
	}
	
	my $style = $prod_obj->get('Style');
	$features{'ProductStyle'} = $style if $style;
	
	my $lp = $prod_obj->get('ListPrice');
	$item->{listprice} = $lp if $lp;
	
	my $fs = $prod_obj->get('FreeShipping');
	$item->{free_shipping} = $fs ? 'Y' : 'N';

	$features{Returnable} = $prod_obj->get('Returnable') ? 'Y' : 'N';
	
	#my $is = get_instock($dbh, $prod_obj);
	#$item->{quantity} = $is ? 1024 : 0;
	$item->{quantity} = 1024;

	$description	.= 'Factory number: <b>' . $intId . '</b><br/><br/>'
		. get_description($dbh, $prod_obj);


	# get the product's options
	my $ov_obj = OptionValue->new;
	$ov_obj->set("Product_ID", $pid);
	my @ov_list = $ov_obj->listSelect($dbh);
	my %ov_hash;
	foreach $ov_obj (@ov_list){
		my $option_id = $ov_obj->get("Option_ID");
		my $option_name = $option_cache{$option_id};
		unless(exists $ov_hash{$option_name}){
			$ov_hash{$option_name} = [];
		}
		my $val = $ov_obj->get("Value");
		# brackets are forbidden for options
		$val =~ s/\[/(/g;
		$val =~ s/\]/)/g;
		push @{$ov_hash{$option_name}}, $val;
	}
	
	while ( my($k, $v) = each %ov_hash ){
		my $hrname = ExportUtils::get_property_name($k);
		my $val = "$hrname:S[".join(',', @$v).']';
		push @options, $val;
	}
	

	# get the product's properties and generate Features
	my $property = Property->new;
	$property->set('Product_ID', $pid);
	$property->set('Ignore', 0);
	my $plist = $property->listSelect($dbh);

	my $price = 0;
	foreach my $pobj (@$plist){
		
		my $compact_name = $pobj->Name;
		my $full_name = ExportUtils::get_property_name($compact_name);
		
		if($compact_name eq 'Price'){
			$price = $pobj->get('Value');
			if($price=~/(.+?)\s-\s.+/){
				$price = $1;
			}
			$price =~ s/\$|,//g;
			# check whether the price value is valid real number
			if($price!~/^[0-9.]+$/){
				print "--------------------------INVALID PRICE\n";
				$price = 0;
			}
			$item->{price} = $price;
			next;
		}

		# brackets are forbidden for features
		my $val = $pobj->get('newValue');
		my $val2 = $pobj->get('newValue2');
		$val =~ s/\[/(/g;
		$val =~ s/\]/)/g;
		$val2 =~ s/\[/(/g;
		$val2 =~ s/\]/)/g;
		
		if(is_feature_multiple($full_name)){
			my @elements = split '-!-', $val;
			$features{$compact_name} = join '///', @elements;
		} elsif(is_feature_range($full_name)) {
			$features{$compact_name} = "$val-$val2"; # a range
		} else {
			$features{$compact_name} = $val;
		}

	}
	
	my $mp = $prod_obj->get('MaxPrice');
	$features{MaximumPrice} = $mp if ($mp != $price);

	$item->{options} = join(';', @options) if @options > 0;

	# process features
	my @fparts;
	foreach my $fname (keys %features){
		my $name = ExportUtils::get_property_name($fname);
		my $feature_obj = $feature_cache{ $name };
		my $fid = $feature_obj->get('CartID');
		my $type = $feature_obj->get('Type');
		push @fparts, '{'.$fid.'}'.$name.":${type}[".$features{$fname}.']';
	}
	$item->{features} = join ';', @fparts if @fparts > 0;
	
	
	# get images
	my @images = $prod_obj->getProductPictures($dbh);
	my %x;
	my %not_x;
	my @y;
	foreach my $image_obj (@images){
		next if $image_obj->get('Status') != 3;
		my $url = $image_obj->get('URL');
		if($url =~ /\/img\/x\/(.+)/) {
			$x{$1} = $image_obj;
		} elsif($url=~/\/img\/[^\/]+\/(.+)/) {
			$not_x{$1} = $image_obj;
		} else {
			push @y, $image_obj;
		}
	}
	my $commit;
	foreach my $key (keys %x){
		if(my $spare_obj = delete $not_x{$key}){
			$spare_obj->set('Status', 15); # deleted as unnecessary
			$spare_obj->update($dbh);
			unlink $spare_obj->getStoragePath();
			$commit = 1;
		}
		push @y, $x{$key};
	}
	$dbh->commit() if $commit;
	foreach my $key (keys %not_x){
		push @y, $not_x{$key};
	}

	my $itype = 'M';
	foreach my $files_obj (@y){
		my $from = $files_obj->getStoragePath;
		my $orgname = $files_obj->getOrgName();
		my $to = $output_vendor_images . '/' . $orgname;
		push @$imagescollector, {
			code => $code,
			type => $itype,
			file => "images/$vsafe/$orgname"
		};
		$itype = 'A';
		unless(-e $to){
			copy($from, $to) or die "$!\n$from\n$to";
		}
	}

	# get manuals
	my $mtext = get_copy_manuals($dbh, $output_vendor_manuals, $vsafe, $prod_obj->ID);
	if($mtext){
		$description .= '<br/><br/><h2>Manuals</h2>'.$mtext;
	}

	$item->{description} = $description;


	push @$collector, $item;
}

sub get_copy_manuals {
	my ($dbh, $path, $vsafe, $product_id) = @_;
	
	my $manual = Manual->new;
	$manual->set('Product_ID', $product_id);
	$manual->markDone();
	my @manuals = $manual->listSelect($dbh);

	my $mtext = '';
	foreach $manual (@manuals){
		my $nm = $manual->Name();

		my $fullname = $manual->getOrgName();
		# split the full name to name and extension
		my $name;
		my $ext;
		if($fullname =~ /(.+)\.(.+)/){
			$name = $1;
			$ext = $2 eq 'ashx' ? 'pdf' : $2;
		} else {
			$name = $fullname;
			$ext = 'pdf';
		}
		
		$mtext .= "<a href='/manuals/$vsafe/$fullname'><img src='/images/ext/$ext.gif' alt='$nm' />&nbsp;$nm</a><br/>";
		my $from = $manual->getStoragePath;
		my $to = "$path/$name.$ext";
		copy $from, $to;
	}

	return $mtext;
	
}

sub get_cat_path {
	my ($dbh, $id) = @_;

	my @parts;

	do {
		unless ( exists $cat_cache{$id} ){
			my $c = Category->new;
			$c->set('ID', $id);
			$c->select($dbh);
			$cat_cache{$id} = $c;
		}

		my $obj = $cat_cache{$id};
		$id = $obj->get('Category_ID');
		# skip root
		if($id){
			my $cn = $obj->Name;
			# replace entities by regular characters
			$cn =~ s/&amp;/&/ig;

			# RESTRICTION!!!
			die "Restricted character in $cn" if $cn=~/;/;

			unshift @parts, $cn;
		}

	} while ($id);

	return join '///', @parts;
}

sub save_csv {
	my ($name, $data_ref, $columns_provider, $encoding) = @_;
	$encoding ||= 'utf-8';

	my $result_ref = format_provider($data_ref, $columns_provider->());

	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";

	foreach my $line (@$result_ref){
		$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}

	close CSV;
}

sub columns_product {
	my @all_columns_ru = (
		{ title=>'Product code', mapto=>'code'},
		{ title=>'Category', mapto=>'category'},
		{ title=>'Product name', mapto=>'name'},
		{ title=>'Description', mapto=>'description'},
		{ title=>'Price', mapto=>'price'},
		{ title=>'Secondary categories', mapto=>'secondary_categories'},
		{ title=>'Options', mapto=>'options'},
		{ title=>'Features', mapto=>'features'},
		{ title=>'Quantity', mapto=>'quantity'},
		{ title=>'List price', mapto=>'listprice'},
		{ title=>'Feature comparison', mapto=>'feature_comparison'},
		{ title=>'Free shipping', mapto=>'free_shipping'},
		{ title=>'Store', mapto=>'store'},
		{ title=>'factory_number', mapto=>'factory_number'},
	);
	return @all_columns_ru;
}

sub columns_files {
	my @all_columns_ru = (
		{ title=>'Product code', mapto=>'code'},
		{ title=>'Pair type', mapto=>'type'},
		{ title=>'Detailed image', mapto=>'file'},
	);
	return @all_columns_ru;
}

sub format_provider {

	my ($data_ref, @columns) = @_;

	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	foreach my $column (@columns){
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
	}

	my $glue_char = ";";

	my @output;

	# make header
	push @output, join ($glue_char, @header_list);

	# process data
	my $col_number = @map_list;

	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = $dataitem->{$key};
			if(defined $value){
				$value =~ s/"/""/g; #";
				$value = '"' . $value . '"';
			} else {
				$value = '';
			}

			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}

	return \@output;

}

sub mkcode {
	my $id = shift;
	$id -= 1;
	my $d1 = int($id / 9999);
	my $d2 = $id % 9999;
	$d2 += 1;
	
	my $c = $chars[ $d1 % @chars ];
	$d1 = int($d1 / @chars);
	$c = $chars[ $d1 ] . $c;
	return "$c-$d2";
}

sub get_cached_page {
	my($dbh, $key) = @_;
	
	if((!defined $key) || (!defined $cached_key)){
		die "\nKey error:\n$key\n$cached_key\n";
	}
	
	if($key eq $cached_key){
		return $cached_content;
	}
	$cached_key = $key;
	$cached_content = undef;
	
	my ($row) = ISoft::DB::do_query($dbh, sql=>"select * from `cache` where `Key`='$key'");
	return undef unless $row;
	my $resp = thaw($row->{Content});
	$cached_content = $resp->decoded_content();
	return $cached_content;
}

sub get_max_price {
	my($dbh, $prod) = @_;
	
	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	my $mp = 0;
	while($content=~/arrOpt\['[\d:]*'\]={price:([\d.]+)/g){
		$mp = $1 if $1 > $mp;
	}
	$prod->set('MaxPrice', $mp);
	
	return $mp;
}

sub get_style {
	my($dbh, $prod) = @_;
	
	my $style = $prod->get('Style');
	return $style if defined $style;
	
	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	if( $content && $content=~/<tr><td><strong>Style<\/strong><\/td><td>(.*?)<\/td><\/tr>/ ){
		$style = $1;
		$style =~ s/\s-\s\d+$//;
	} else {
		$style = '';
	}
	
	$prod->set('Style', $style);
	
	return $style;
}

sub get_list_price {
	my($dbh, $prod) = @_;
	
	my $lp = $prod->get('ListPrice');
	return $lp if defined $lp;

	$lp = 0;

	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	if( $content && $content=~/>List Price<\/div><div id="divMSRP" [^>]*>\$([0-9.,]+)<\/div>/ ){
		$lp = $1;
		$lp =~ s/,//g;
	}

	$prod->set('ListPrice', $lp);

	return $lp;
}

sub get_free_shipping {
	my($dbh, $prod) = @_;
	
	my $fs = $prod->get('FreeShipping');
	return $fs if defined $fs;

	$fs = 0;

	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	if( $content && $content=~/<div id="divShipping"[^>]+>([^<]+)/ ){
		my $data = $1;
		if($data =~ /^ \+ (Free Shipping|Free Delivery)/){
			$fs = 1;
		} else {
			die "bad shipping value in ".$prod->ID;
		}
	}

	$prod->set('FreeShipping', $fs);

	return $fs;
}

sub get_instock {
	my($dbh, $prod) = @_;
	
	my $is = $prod->get('InStock');
	return $is if defined $is;

	$is = 0;

	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	if( $content && $content=~/<div id="tdStockInfo"[^>]*>([^<]+)<\/div>/ ){
		my $data = $1;
		if($data =~ /^In Stock$/){
			$is = 1;
		} else {
			die "bad instock value in ".$prod->ID;
		}
	}

	$prod->set('InStock', $is);

	return $is;
}

sub get_description {
	my($dbh, $prod) = @_;
	
	my $descr = $prod->get('NewDescription');
	return $descr if defined $descr;

	$descr = $prod->get('Description') || '';

	# try to extract;
	my $content = get_cached_page($dbh, $prod->getMD5());
	
	#open XX, '>content.htm';
	#print XX $content;
	#close XX;
	
	if( $content ){
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($content);

		$descr = $tree->findvalue( q{//div[@class="gutIn"]/div[@class="gutIn cgd warning"]} ) || '';
		$descr = "<div class='cgd-warning'>" . $descr . '</div>' if $descr;
		my @nodes = $tree->findnodes( q{//div[@id="prodDesc"]/div[@itemprop="description"]} );
		foreach my $node (@nodes){
			$descr .= $prod->asHtml($node);
		}
		
		$tree->delete();
	}

	$prod->set('NewDescription', $descr);
	$prod->set('Description', undef);

	return $descr;
}

