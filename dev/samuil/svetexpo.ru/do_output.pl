use strict;
use warnings;

use utf8;

use Encode qw/encode decode/;
use File::Path;
use File::Copy;
use Image::Resize;
use Error ':try';
use URI;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;
#use Property;
#use Vendor;
#use Translit;


# initialization

our $CAT_LIMIT   = 0;
our $PROD_LIMIT  = 0;

our $prefix = 'svex';
our $article_mask = $prefix . '-%05d';

our $verbose_top_categories = 1;
our $verbose_categories = 1;
our $verbose_products = 1;
our $verbose_vendors = 1;

our %images;
#our %skip_reg;

# cached Category objects
our %cat_cache;

# the pictures below must be created from the largest file
# because medium files contain watermarks
our %alt_pictures = (
	"torsher-552.jpg" => 1,
	"torsher-712.jpg" => 1,
	"torsher-718.jpg" => 1,
	"potolochnyj-svetilnik-1025-4-dif.jpg" => 1,
);

our $src_product_pictures = $constants{SourceFiles}{PRODUCT_PICTURES};
#our $src_vendor_pictures = $constants{SourceFiles}{VENDOR_PICTURES};
our $csv_dir = $constants{DestinationFiles}{CSV_DIR};
our $output_pictures = $constants{DestinationFiles}{PRODUCT_PICTURES};

our $convert = $constants{ImageMagick}{CONVERT};
our $composite = $constants{ImageMagick}{COMPOSITE};

unless (-e $output_pictures && -d $output_pictures){
	mkpath($output_pictures);
}

unless (-e $csv_dir && -d $csv_dir){
	mkpath($csv_dir);
}

our $dbh = get_dbh();

# do work

process_data();

release_dbh($dbh);

exit;

######################


sub process_data {
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	my @toplist = $root->getCategories($dbh);
	my @collector = (
	);
	
	my @tree_cat;
	
	my $order = 1;
	my $counter = $CAT_LIMIT;
	foreach my $topitem (@toplist){
		process_category($topitem, \@collector, \@tree_cat, '', '', '', $order++);
		print "Top category processed\n" if $verbose_top_categories;
		if($CAT_LIMIT){
			last unless --$counter;
		}
	}
	
#	add_vendors(\@collector, $order);
	
#	save_csv("$csv_dir/full.csv", \@collector, 'utf-8');
#	foreach my $r (@collector){
#		if ($r->{is_prod}){
#			# this is a product
#			$r->{description} = $r->{vendorlink};
#		} else {
#			delete $r->{description};
#		}
#	}
#	save_csv("$csv_dir/import.csv", \@collector, 'utf-8');
#	
#	open SK, '>skiplist.txt';
#	while( my($key, $val) = each %skip_reg ){
#		print SK "$key\n$val\n\n";
#	}
#	close SK;
	
	
}

sub process_category {
	my ($category, $collector, $tree_cat, $namelist, $spacer, $parentname, $order) = @_;
	
	my $cat_id = $category->ID;
	
	print "Process category $cat_id\n" if $verbose_categories;
	
	my $catname = $category->Name;
	$catname =~ s/\r|\n|\t/ /g;
	
	my $name = $spacer.$catname;
	my $n_c = $namelist.$catname;

	my %h = (
		name => $name,
		page_id => $n_c,
		suppress_defaults => 1,
		
		page_title => $category->get("PageTitle"),
		meta_keywords => $category->get("PageMetakeywords"),
		meta_description => $category->get("PageMetaDescription"),
	);
	
	$h{sort_order} = $order if defined $order;

	my $tc_item = {
		name => $catname,
		items => []
	};
	push @$tree_cat, $tc_item;
	
	
	# get a picture
	
	# 'catalog.2.' must be 'catalog.3.' for the next data source (parsing)
	
	my $pic_file = 'catalog.2.'.$cat_id.'.jpg';
	my $path_name = "$output_pictures/$pic_file";
	unless(-e $path_name){
		my @piclist;
		get_category_pictures($category, \@piclist);
		if(@piclist > 0){
			my $picture = $piclist[ int(rand(scalar @piclist)) ];
			my $pic_id = $picture->ID;
			my $picname = sprintf '%09d.jpg', $pic_id;
			die "no picture" unless -e "$src_product_pictures/$picname";
			category_thumb("$src_product_pictures/$picname", $path_name);
			$h{picture_1} = $pic_file;
		} else {
			print "No picture for category $cat_id\n";
		}
	}
	
#	push @$collector, \%h;
#	
#	$parentname = $parentname.' '.$category->Name;
#	process_products($category, $collector, $n_c, $parentname);
#
#	my @sublist = $category->getCategories($dbh);
#	foreach my $item (@sublist){
#		process_category($item, $collector, $tc_item->{items}, "$n_c-", $spacer.'!', $parentname);
#	}
	
}

sub get_category_pictures {
	my($category, $storage) = @_;
	# check sub categories
	my @sublist1 = $category->getCategories($dbh);
	get_category_pictures($_, $storage) foreach @sublist1;
	# get products
	my @sublist2 = $category->getProducts($dbh);
	foreach my $prod_obj (@sublist2){
		my @pics = $prod_obj->getProductPictures($dbh);
		push @$storage, @pics;
	}
	
}

sub category_thumb {
	my ($from, $to) = @_;
	try {
		# create Resizer
		my $resize = Image::Resize->new( $from );
		my $width = $resize->width();
		my $height = $resize->height();
		my $gd;
		# small thumbnail
		if($width > 100 || $height > 100){
			$gd = $resize->resize(100, 100);
		} else {
			$gd = $resize->gd();
		}
		open XX, ">$to" or die "!!v";
		binmode XX;
		print XX $gd->jpeg();
		close XX;
		
	} otherwise {
		die "Image $from caused an exception\n";
	};
	
}

#sub add_vendors {
#	my ($collector, $order) = @_;
#	
#	# get all vendors
#	my $vnd = Vendor->new();
#	#$vnd->set('Status', 3);
#	my @vendors = $vnd->selectAll($dbh);
#	
#	push @$collector, {
#		name => "Фабрики производители",
#		page_id => "vendors",
#		suppress_defaults => 1,
#		sort_order => $order
#	};
#	
#	my $spacer = '!';
#	
#	my $skip = {
#		"Wunderlicht" => 1,
#		"Odeon Light" => 1,
#		"Massive" => 1,
#		"Sonex" => 1,
#		"Blitz" => 1,
#		"Citilux" => 1,
#		#"Padana Lampadari" => 1,
#		#"Vidrios Granada" => 1,
#		#"LightStar" => 1,
#		#"Artelamp" => 1,
#		#"MW LIGHT" => 1,
#		"Eglo" => 1,
#		"Globo" => 1,
#		"Lussole" => 1,
#		"Steinel" => 1,
#		#"Royal Decor" => 1,
#		"Vinco" => 1,
#		"Nordik" => 1,
#		"ГИРЛЯНДЫ, СВЕТОВЫЕ ФИГУРЫ" => 1,
#		#"Reccagni Angelo" => 1,
#		#"Bejorama" => 1,
#		#"La Lampada" => 1,
#		#"CHIARO" => 1,
#	};
#
#	foreach my $vendor (@vendors){
#		my $id = $vendor->ID;
#		my $name = $vendor->get('Name');
#		next if $skip->{$name};
#		print "Vendor: $name\n" if $verbose_vendors;
#		my $page_id = "vendors-".Translit::convert($name);
#		$page_id =~ s/[, ]+/-/g;
#		
#		my $vi = {
#			name => "$spacer$name",
#			page_id => $page_id,
#			suppress_defaults => 1
#		};
#		
#		my $d = $vendor->get('Description');
#		$d =~ s/href="[^"]+"/href="http:\/\/proartsvet.ru\/"/g; #"
#		$vi->{description} = $d if $d;
#		
#		my $img_name = '';
#		my($row) = ISoft::DB::do_query($dbh, sql=>"select * from vendorpicture where vendor_id=$id and url!=''");
#		
#		if ($row){
#			my $pic_id = $row->{ID};
#			my $source = "$src_vendor_pictures/$pic_id.png";
#			my $pic_url = $row->{URL};
#			print "$pic_url\n" if $verbose_vendors;
#			if($pic_url =~ /.+\/(.+)\.png$/i){
#				print "image ok\n" if $verbose_vendors;
#				$img_name = $1.'.jpg';
#				my $storename = $output_pictures.'/'.$img_name;
#				category_thumb($source, $storename) unless -e $storename;
#			}
#		}
#		
#		$vi->{picture_1} = $img_name;
#		push @$collector, $vi;
#
#	}
#	
#}
#
#sub process_product {
#	my($product, $collector, $namelist, $parentcategoryname) = @_;
#	
#	my $product_id = $product->ID;
#	
#	print "Process product $product_id\n" if $verbose_products;
#	
#	# skip the product if it has no pictures
#	my @pics = $product->getProductPictures($dbh);
#	if(@pics==0){
#		$skip_reg{$product->get("URL")} = "No pictures";
#		return;
#	}
#		
#	my @properties = Property->new()->set('Product_ID', $product_id)->listSelect($dbh); 
#	# no properties - skip the product
#	if(@properties==0){
#		$skip_reg{$product->get("URL")} = "No properties";
#		return;
#	}
#	
#	# transform the array to hash
#	my %property = map { $_->get('Name') => $_->get('Value') } @properties;
#	
#	my $price = $product->get('Price');
#	if($price){
#		$price = int( $price * 0.88 );
#	} else {
#		$price = 100;
#	}
#
#	my $descr = $product->get('Description');
#	$descr =~ s/href="[^"]+"/href="http:\/\/proartsvet.ru\/"/g; #"
#
#	my $org_code = $product->get('ProductCode');
#	$org_code=~s/^\s+//;
#	$org_code=~s/\s+$//;
#
#	my $name = $product->Name;
#	$name=~s/^\s+//;
#	$name=~s/\s+$//;
#	
#	my %h = (
#		is_prod => 1,
#		code => $product->get('InternalID'),
#		code1 => $org_code,
#		name => $name,
#		price => $price,
#		categoryname => $parentcategoryname,
#		page_title => $product->get('PageTitle') . " ПроАртСвет",
#		meta_keywords => $product->get('PageMetakeywords') . " ПроАртСвет",
#		meta_description => $product->get('PageMetaDescription') . " ПроАртСвет",
#	);
#	
#	my $page_id = $namelist.'-';
#	my $vendorlink = '<br/><br/>По наличию товара на складе и срокам поставки уточняйте у дизайн-менеджеров.<br/><br/>';
#	my $vendor_a = '';
#	
#	my %reps;
#	
#	#######################################################################
#	
#	foreach my $def (@Product::all_properties){
#		
#		my $nm = $def->{name};
#		my $val;
#		
#		if($def->{inprod}){
#			$val = $product->get($def->{field});
#		} else {
#			$val = $property{ $nm };
#		}
#		
#		next unless defined $val;
#		
#		if($nm eq 'Материалы'){
#			$val =~ s/покрытия\s+//g;
#		}
#
#		$h{$nm} = $val;
#		
#		if($nm eq 'Фабрика'){
#			
#			my $xn = $val;
#			$val =~ s/[, ]+/-/g;
#			$page_id .= "$val-";
#			my $href = Translit::convert($val);
#			$vendor_a = "<a href='/category/vendors-$href/'>$xn</a>";
#			$vendorlink .= "Посмотрите всю продукцию фабрики производителя $vendor_a<br/><br/>";
#			
#		} elsif ($def->{tagged}){
#
#			my $query = URI->new('/search/');
#			$query->query_form({tag => $val});
#			$reps{$nm} = "<a href='" . $query->as_string() . "'>$val</a>";
#			
#		}
#		
#	}
#	
#	# two magick phrases
#	$vendorlink .= "Цена на товар может отличаться в зависимости от выбранных материалов и покрытий.<br/>Если Вы нашли товары по цене дешевле чем в нашем Интернет магазине, то обязательно звоните нам, мы всегда Вам предоставим дополнительные скидки в 5% от цен конкурентов!<br/><br/>";
#	
#	# people & box
#	$vendorlink .= $product->getBox(\%property);
#	
#	# generate short description
#	if($vendor_a){
#		$reps{'Фабрика'} = $vendor_a;
#	}
#	$h{brief_description} = build_brief($product, \%property, \%reps);
#
#	$h{vendorlink} = $vendorlink;
#	
#	$h{description} = $vendorlink.$descr;
#	$page_id .= $name;
#	$h{page_id} = $page_id;
#	
#	my $picnumber = 1;
#	foreach my $pic_obj (@pics){
#		
#		my $safe_name = Translit::convert($name);
#		# remove all unsafe characters
#		$safe_name =~ s/[^a-z0-9\-_.]/-/g;
#		
#		unless($safe_name){
#			die "no name";
#		}
#		
#		my $postfix = '';
#		if(exists $images{$safe_name}){
#			$postfix = '_'.$images{$safe_name}++;
#		} else {
#			$images{$safe_name} = 1;
#		}
#		
#		my $small_name = "$safe_name${postfix}_thm.jpg";
#		my $medium_name = "$safe_name${postfix}.jpg";
#		my $org_name = "$safe_name${postfix}_enl.jpg";
#		
#		unless(-e "$output_pictures/$medium_name"){
#			# image does not exist, do convertation
#			
#			my $pic_id = $pic_obj->ID;
#			my $src_medium = "$src_product_pictures/$pic_id.jpg";
#			my $src_large = "$src_product_pictures/$pic_id-enl.jpg";
#			
#			if(exists $alt_pictures{$medium_name}){
#				
#				#print "$src_medium\n$src_large\n\n";
#								
#				# composite with Logo
#				my $cmd = "$composite -gravity SouthEast -geometry -3+11 logo_5.png \"$src_large\" \"$output_pictures/$org_name\"";
#				`$cmd`;
#				# resize to 300x300
#				$cmd = "$convert -resize \"300x300>\" \"$output_pictures/$org_name\" \"$output_pictures/$medium_name\"";
#				`$cmd`;
#				# resize to 150x150
#				$cmd = "$convert -resize \"150x150>\" \"$output_pictures/$org_name\" \"$output_pictures/$small_name\"";
#				`$cmd`;
#				
#			} else {
#				#### set 0 to disable common images - for testing only
#				if(1){
#					# resize to 150x150
#					my $cmd = "$convert -resize \"150x150>\" \"$src_medium\" \"$output_pictures/$small_name\"";
#					`$cmd`;
#					# resize to 300x300
#					$cmd = "$convert -resize \"300x300>\" \"$src_medium\" \"$output_pictures/$medium_name\"";
#					`$cmd`;
#					# composite with Logo
#					$cmd = "$composite -gravity SouthEast -geometry -3+11 logo_5.png \"$src_large\" \"$output_pictures/$org_name\"";
#					`$cmd`;
#				}
#			}
#
#		}
#		
#		# store into the product's info
#		$h{"picture_".$picnumber++} = "$medium_name,$small_name,$org_name";
#		
#	}
#	
#	push @$collector, \%h;
#	
#}
#
#sub build_brief {
#	my ($product, $property, $replacements) = @_;
#	
#	my $rows = '';
#	
#	foreach my $def (@Product::brief_content){
#
#		my $nm = $def->{name};
#		my $val = '';
#		
#		if($replacements->{$nm}){
#			$val = $replacements->{$nm}
#		} else {
#			if($def->{inprod}){
#				$val = $product->get($def->{field});
#			} else {
#				$val = $property->{$nm};
#			}
#		}
#
#		if($val){
#			#$value =~ s/'/"/g; #' ...and no styles for now
#			$rows .= "<tr><td>$nm</td><td>$val</td></tr>";
#		}
#		
#	}
#	
#	if($rows){
#		return "<table>$rows</table>";
#	}
#	
#	return '';
#}
#
#
#
#sub process_products {
#	my ($category, $collector, $namelist, $parentcategoryname) = @_;
#	my @prodlist = $category->getProducts($dbh, $PROD_LIMIT);
#	process_product($_, $collector, $namelist, $parentcategoryname) foreach @prodlist;
#}
#
#
#
#sub update_codes {
#	my $prod = shift;
#	my $pid = $prod->ID;
#	$prod->set('ProductCode', $prod->get('InternalID'));
#	$prod->set('InternalID', sprintf $article_mask, $pid);
#	$prod->update($dbh);
#	$dbh->commit();
#}
#
#sub delete_product {
#	my $prod = shift;
#	
#	my $pid = $prod->ID;
#	print "Deleting $pid\n";
#	
#	# property
#	ISoft::DB::do_query($dbh, sql=>"delete from `Property` where `Product_ID`=$pid");
#	
#	# picture
#	my @piclist = $prod->getProductPictures($dbh);
#	foreach my $picobj(@piclist){
#		my $picid = $picobj->ID;
#		print "Deleting picture $picid\n";
#		unlink "$src_product_pictures/$picid.jpg";
#		unlink "$src_product_pictures/${picid}-enl.jpg";
#		$picobj->delete($dbh);
#	}
#	
#	# self
#	$prod->delete($dbh);
#	
#}
#
#sub save_csv {
#	my ($name, $data_ref, $encoding) = @_;
#	$encoding ||= 'cp1251';
#	
#	my $result_ref = webassyst_provider($data_ref);
#	
#	open (CSV, '>', $name)
#		or die "Cannot open file $name: $!";
#		
#	foreach my $line (@$result_ref){
#		$line = encode($encoding, $line, Encode::FB_DEFAULT);
#		print CSV $line, "\n";
#	}
#	
#	close CSV;
#}
#
#sub webassyst_provider {
#
#	my $data_ref = shift;
#	
#	# columns definition - webasyst CSV format
#	
#	my @all_columns_ru = (
#		{ title=>'Артикул', mapto=>'code', force_quote=>1},
#		{ title=>'Наименование (Русский)', mapto=>'name'},
#		{ title=>'Наименование (English)', mapto=>'name_en'},
#		{ title=>'"ID страницы (часть URL; используется в ссылках на эту страницу)"', mapto=>'page_id'},
#		{ title=>'Цена', mapto=>'price'},
#		{ title=>'Название вида налогов', mapto=>'tax_type', default=>''},
#		{ title=>'Скрытый', mapto=>'invisible', default=>'0'},
#		{ title=>'Можно купить', mapto=>'available', default=>'1'},
#		{ title=>'Старая цена', mapto=>'regular_price'},
#		{ title=>'На складе', mapto=>'none', default=>'1'},
#		{ title=>'Продано', mapto=>'sold', default=>'0'},
#		
#		{ title=>'Описание (English)', mapto=>'description_en'},
#		{ title=>'Описание (Русский)', mapto=>'description', quote=>1},
#		
#		{ title=>'Краткое описание (English)', mapto=>'brief_description_en'},
#		{ title=>'Краткое описание (Русский)', mapto=>'brief_description'},
#		
#		{ title=>'Сортировка', mapto=>'sort_order'},
#		
#		{ title=>'Заголовок страницы (English)', mapto=>'page_title_en'},
#		{ title=>'Заголовок страницы (Русский)', mapto=>'page_title'},
#		
#		{ title=>'Тэг META keywords (English)', mapto=>'meta_keywords_en'},
#		{ title=>'Тэг META keywords (Русский)', mapto=>'meta_keywords'},
#		
#		{ title=>'Тэг META description (English)', mapto=>'meta_description_en'},
#		{ title=>'Тэг META description (Русский)', mapto=>'meta_description'},
#		
#		{ title=>'Стоимость упаковки', mapto=>'h_charge'},
#		{ title=>'Вес продукта', mapto=>'weight'},
#		{ title=>'Бесплатная доставка', mapto=>'free_shipping', dafault=>'0'},
#		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'min_order_quantity', dafault=>'1'},
#		{ title=>'Файл продукта', mapto=>'digital_filename'},
#		{ title=>'Количество дней для скачивания', mapto=>'download_days', dafault=>'5'},
#		{ title=>'Количество загрузок (раз)', mapto=>'downloads_number', dafault=>'5'},
#		
#		{ title=>'Фотография', mapto=>'picture_1', quote=>1},
#
#		{ title=>'Артикул товара (Русский)', mapto=>'code1' },
#		{ title=>'Фабрика (Русский)', mapto=>'Фабрика' },
#		{ title=>'Производство (Русский)', mapto=>'Производство' },
#		{ title=>'Высота (Русский)', mapto=>'Высота' },
#		{ title=>'Диаметр (Русский)', mapto=>'Диаметр' },
#		{ title=>'Ширина (Русский)', mapto=>'Ширина' },
#		{ title=>'Длина (Русский)', mapto=>'Длина' },
#		{ title=>'Тип цоколя (Русский)', mapto=>'Тип цоколя' },
#		{ title=>'Акция (Русский)', mapto=>'Акция' },
#		{ title=>'Экономия (Русский)', mapto=>'Экономия' },
#		{ title=>'Вес (Русский)', mapto=>'Вес' },
#		{ title=>'Выступ от стены (Русский)', mapto=>'Выступ от стены' },
#		
#		{ title=>'Количество ламп (Русский)', mapto=>'Количество ламп' },
#		{ title=>'Материалы (Русский)', mapto=>'Материалы' },
#		{ title=>'Мощность ламп (Русский)', mapto=>'Мощность ламп' },
#		{ title=>'Категория (Русский)', mapto=>'categoryname' },
#		
#		
#		
#
#	);	
#	
#	# prepare for parsing of input data_ref
#	my @header_list;
#	my @map_list;
#	my @defaults;
#	my @quotes;
#	my @forcedquotes;
#	foreach my $column (@all_columns_ru){
#		
#		push @header_list, $column->{title};
#		push @map_list, $column->{mapto};
#		push @defaults, exists $column->{default} ? $column->{default} : '';
#		push @quotes, exists $column->{quote} ? $column->{quote} : 0;
#		push @forcedquotes, exists $column->{force_quote} ? $column->{force_quote} : 0;
#	}
#	
#	my $glue_char = ";";
#	
#	my @output;
#	
#	# make header
#	push @output, join ($glue_char, @header_list);
#	
#	# process data
#	my $col_number = @map_list;
#	
#	foreach my $dataitem (@$data_ref){
#		my $cn = 0;
#		my $suppress_defaults = $dataitem->{suppress_defaults} ? 1 : 0;
#		my @parts;
#		while ($cn < $col_number){
#			my $key = $map_list[$cn];
#			my $value = exists $dataitem->{$key} ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
#			my $quote = $quotes[$cn];
#			my $force_quote = $forcedquotes[$cn];
#			
#			$value =~ s/"/""/g; #";
#			
#			if($force_quote || ($value ne '')){
#				if ($force_quote || $quote || $value =~ /$glue_char/o ){
#					$value = '"' . $value . '"';
#				}
#			}
#			
#			push @parts, $value;
#			$cn++;
#		}
#		push @output, join ($glue_char, @parts);
#	}
#	
#	return \@output;
#	
#}
#
#sub get_category {
#	my $cid = shift;
#	return $cat_cache{$cid} if exists $cat_cache{$cid};
#	my $cat_obj = Category->new()->set('ID', $cid);
#	$cat_obj->select($dbh);
#	$cat_cache{$cid} = $cat_obj;
#	return $cat_obj;
#}