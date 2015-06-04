use strict;
use warnings;

use utf8;

use File::Path;
use File::Copy;
use Image::Resize;
use Encode qw/encode decode/;
use LWP::Simple;
use URI;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;
use ISoft::ParseEngine::Member::File::ProductPicture;
use Translit;
use VendorInfo;

our $prefix = 'exlt';

our $article_mask = $prefix . '%05d';

our $output = 'z:/P_FILES/samuil/expresslight.ru/output';
our $output_pictures = $output . '/products_pictures';

unless (-e $output_pictures && -d $output_pictures){
	mkpath($output_pictures);
}

#die "Done";

process_data();

exit;


####################################################


sub process_data {
	
	my $dbh = get_dbh();
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	
	my @toplist = $root->getCategories($dbh);

	my @collector = (
	);
	
	my @tree_cat;
	
	my $order = 1;
	
	foreach my $topitem (@toplist){
		process_category($dbh, $topitem, \@collector, \@tree_cat, '', '', '', $order++);
		print "Top category processed\n";
	}
	
#	add_vendors($dbh, \@tree_cat, \@collector, $order);
	
	save_csv("$output/full.csv", \@collector, 'utf-8');
	
	foreach my $r (@collector){
		if ($r->{is_prod}){
			# this is a product
			$r->{description} = $r->{vendorlink};
		} else {
			delete $r->{description};
		}
	}
	save_csv("$output/import.csv", \@collector, 'utf-8');
	
	$dbh->rollback();
	
}

sub add_vendors {
	my ($dbh, $tree_cat, $collector, $order) = @_;
	
	# get all vendors
	my $sql = "select distinct(vendor) from product order by vendor asc";
	my $rows = ISoft::DB::do_query($dbh, sql=>$sql, arr_ref=>1);
	
	push @$collector, {
		name => "Фабрики производители",
		page_id => "vendors",
		suppress_defaults => 1,
		sort_order => $order
	};
	
	my $spacer = '!';
	
	foreach my $row (@$rows){
		my $vendor = $row->[0];
		my $page_id = "vendors-".Translit::convert($vendor);
		$page_id =~ s/[, ]+/-/g;
		
		my $vi = {
			name => "$spacer$vendor",
			page_id => $page_id,
			suppress_defaults => 1
		};
		
		my $d = VendorInfo::get_text($vendor);
		$vi->{description} = $d if $d;
		
		my $img_name = '';
		if (my $isrc = VendorInfo::get_icon($vendor)){
			if($isrc =~ /.+\/(.+)$/){
				$img_name = $1;
				$img_name =~ s/%20/_/g;
				my $storename = $output_pictures.'/'.$img_name;
				unless (-e $storename){
					print "Downloading $img_name\n";
					getstore($isrc, $storename);
					category_thumb($storename);
				}
				
			}
		}
		
		$vi->{picture_1} = $img_name;
		push @$collector, $vi;

		# temporary blocked
#		foreach my $tree_item (@$tree_cat){
#			add_vendor_category($collector, $tree_item, $spacer.'!', $page_id); 
#		}
		
	}
	
}

sub add_vendor_category {
	my ($collector, $tree_item, $spacer, $page_id) = @_;
	
	my $catname = $tree_item->{name};
	my $ctn = Translit::convert($catname);
	$ctn =~ s/[, ]+/-/g;
	$page_id .= '-'.$ctn;
	
	push @$collector, {
		name => "$spacer$catname",
		page_id => $page_id,
		suppress_defaults => 1
	};
	
	foreach ( @{$tree_item->{items}} ){
		add_vendor_category($collector, $_, $spacer.'!', $page_id);
	}
	
}

sub save_csv {
	my ($name, $data_ref, $encoding) = @_;
	$encoding ||= 'cp1251';
	
	my $result_ref = webassyst_provider($data_ref);
	
	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";
		
	foreach my $line (@$result_ref){
		$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	
	close CSV;
}

sub get_category_pictures {
	my($dbh, $cat_id, $storage) = @_;

	# check sub categories
	my $tmp_obj = Category->new;
	$tmp_obj->set('Category_ID', $cat_id);
	my @sublist = $tmp_obj->listSelect($dbh);
	get_category_pictures($dbh, $_->ID, $storage) foreach @sublist;
	
	# get products
	@sublist = ();
	$tmp_obj = Product->new;
	$tmp_obj->set('Category_ID', $cat_id);
	@sublist = $tmp_obj->listSelect($dbh);
	
	foreach $tmp_obj (@sublist){
		
		my $picture = ISoft::ParseEngine::Member::File::ProductPicture->new;
		$picture->set('Product_ID', $tmp_obj->ID);
		$picture->markDone();
		push @$storage, $picture if $picture->checkExistence($dbh);
		
	}
	
}

sub process_category {
	my ($dbh, $category, $collector, $tree_cat, $namelist, $spacer, $parentname, $order) = @_;
	
	my $cat_id = $category->ID;
	
	my $catname = $category->Name;
	$catname =~ s/\r|\n|\t/ /g;
	$catname =~ s/^\s+//;
	$catname =~ s/\s+$//;
	
	my $name = $spacer.$catname;
	my $n_c = $namelist.$catname;

	my %h = (
		name => $name,
		page_id => $n_c,
		suppress_defaults => 1,
		
		page_title => "$catname - купить недорого в интернет-магазине ProArtSvet",
		meta_keywords => $catname,
		meta_description => $catname,
	);
	
	$h{sort_order} = $order if defined $order;

	my $tc_item = {
		name => $catname,
		items => []
	};
	push @$tree_cat, $tc_item;
	
	
	# get a picture
	my @piclist;
	get_category_pictures($dbh, $cat_id, \@piclist);
	if(@piclist > 0){
		my $picture = $piclist[ int(rand(scalar @piclist)) ];
		my $pic_file = 'catalog'.$cat_id.'.jpg';
		# remove all unsafe characters
		#$pic_file =~ s/[^a-z0-9\-_.]/-/g;
		my $path_name = "$output_pictures/$pic_file";
		copy($picture->getStoragePath(), $path_name);
		category_thumb($path_name);
		$h{picture_1} = $pic_file;
	} else {
		print "No picture for category $cat_id\n";
	}
	
	push @$collector, \%h;
	
	$parentname = $parentname.' '.$category->Name;
	process_products($dbh, $category, $collector, $n_c, $parentname);

	my @sublist = $category->getCategories($dbh);
	foreach my $item (@sublist){
		process_category($dbh, $item, $collector, $tc_item->{items}, "$n_c-", $spacer.'!', $parentname);
	}
	
}

sub process_products {
	my ($dbh, $category, $collector, $namelist, $parentcategoryname) = @_;
	
	my $cnt = 4;
	
	my @prodlist = $category->getProducts($dbh);
	foreach my $product (@prodlist){
		next if $product->isFailed();
		
		#last unless $cnt--;
		
		process_product($dbh, $product, $collector, $namelist, $parentcategoryname);
	}
	
}

our %images;

sub process_product {
	my($dbh, $product, $collector, $namelist, $parentcategoryname) = @_;
	
	# skip product if it has no pictures
	my @pics = $product->getProductPictures($dbh);
	return if @pics==0;
	
	my $price = $product->get('Price');

	my $descr = $product->get('Description');
	$descr =~ s/href="[^"]+"/href="http:\/\/proartsvet.ru\/"/g; #"

	my $org_code = $product->get('ProductCode');
	$org_code=~s/^\s+//;
	$org_code=~s/\s+$//;

	my $name = $product->Name;
	if($name){
		$name=~s/^\s+//;
		$name=~s/\s+$//;
	} else {
		$name = $org_code;
	}
	
	if($name eq $org_code){
		# add category name
		my $cid = $product->get('Category_ID');
		my $cat;
		do {
			
			$cat = Category->new;
			$cat->set('ID', $cid);
			$cat->select($dbh);
			$cid = $cat->get('Category_ID');
			
		} while ($cat->get('Level') > 1);
		
		
		my $cn = $cat->Name;
		$cn =~ s/\r|\n|\t/ /g;
		$cn =~ s/^\s+//;
		$cn =~ s/\s+$//;
		$name = "$cn $name";
	}
	
	my %h = (
		is_prod => 1,
		code => $product->get('InternalID'),
		code1 => $org_code,
		name => $name,
		categoryname => $parentcategoryname,
		price => $price || 100,
		#description => $descr,
		
		#brief_description => build_brief($product),
		
		page_title => "$name - купить недорого в интернет-магазине ProArtSvet",
		meta_keywords => $name,
		meta_description => $name,
		
	);
	
	my $page_id = $namelist.'-';
	my $vendorlink = '<br/><br/>По наличию товара на складе и срокам поставки уточняйте у дизайн-менеджеров.<br/><br/>';
	my $vendor_a = '';
	
	my %reps;

	foreach my $key (values %Product::mapping){
		my $x = $product->get($key);
		$x = '' unless defined $x;
		$h{$key} = $x;
		
		next unless $x;
		
		if($key eq 'Armature' || $key eq 'Production'){
			my $query = URI->new('/search/');
			$query->query_form({tag => $x});
			$reps{$key} = "<a href='" . $query->as_string() . "'>$x</a>";
		}
		
		if($key eq 'Vendor'){
			my $xn = $x;
			$x =~ s/[, ]+/-/g;
			$page_id .= "$x-";
			my $href = Translit::convert($x);
			$vendor_a = "<a href='/category/vendors-$href/'>$xn</a>";
			$vendorlink .= "Посмотрите всю продукцию фабрики производителя $vendor_a<br/><br/>";
		}
		
	}
	
	# two magick phrases
	$vendorlink .= "Цена на товар может отличаться в зависимости от выбранных материалов и покрытий.<br/>Если Вы нашли товары по цене дешевле чем в нашем Интернет магазине, то обязательно звоните нам, мы всегда Вам предоставим дополнительные скидки в 5% от цен конкурентов!<br/><br/>";

	# people & box
	$vendorlink .= $product->getBox();
	
	# generate short description
	if($vendor_a){
		$reps{vlink} = $vendor_a;
	}
	$h{brief_description} = build_brief($product, %reps);
	
	
	$h{vendorlink} = $vendorlink;
	
	$h{description} = $vendorlink.$descr;
	$page_id .= $name;
	$h{page_id} = $page_id;
	
	
	foreach my $pic_obj (@pics){
		
		my $safe_name = Translit::convert($name);
		# remove all unsafe characters
		$safe_name =~ s/[^a-z0-9\-_.]/-/g;
		
		unless($safe_name){
			die "no name";
		}
		
		my $postfix = '';
		if(exists $images{$safe_name}){
			$postfix = '_'.$images{$safe_name}++;
		} else {
			$images{$safe_name} = 1;
		}
		
		my $small_name = "$safe_name${postfix}_thm.jpg";
		my $medium_name = "$safe_name${postfix}.jpg";
		my $org_name = "$safe_name${postfix}_enl.jpg";
		
		unless(-e "$output_pictures/$medium_name"){
			# image does not exist, do convertation
			
			my $src = $pic_obj->getStoragePath();
			
			# resize to 150x150
			my $cmd = "d:\\tools\\ImageMagick\\convert.exe -resize \"150x150>\" \"$src\" \"$output_pictures/$small_name\"";
			`$cmd`;

			# resize to 300x300
			$cmd = "d:\\tools\\ImageMagick\\convert.exe -resize \"300x300>\" \"$src\" \"$output_pictures/$medium_name\"";
			`$cmd`;

			# composite with Logo
			$cmd = "d:\\tools\\ImageMagick\\composite.exe -gravity SouthEast logo2.png \"$src\" \"$output_pictures/$org_name\"";
			`$cmd`;
		}
		
		# store into the product's info
		$h{"picture_1"} = "$medium_name,$small_name,$org_name";
		
		# only one picture in this case!!!
		last;
		
	}
	
	push @$collector, \%h;
	
}

sub build_brief {
	my ($product, %replacements) = @_;
	
	my $rows = '';
	
	foreach my $item (@Product::short_description_content){
		my $name = $item->[0];
		my $field = $item->[1];
		my $r = $item->[2];
		
		my $value;
		if($r && $replacements{$r}){
			$value = $replacements{$r}
		} else {
			$value = $product->get($field)
		}
		if($value){
			#$value =~ s/'/"/g; #' ...and no styles for now
			$rows .= "<tr><td>$name</td><td>$value</td></tr>";
		}
		
	}
	
	if($rows){
		return "<table>$rows</table>";
	}
	
	return '';
}

sub webassyst_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'Артикул', mapto=>'code', force_quote=>1},
		{ title=>'Наименование (Русский)', mapto=>'name'},
		{ title=>'Наименование (English)', mapto=>'name_en'},
		{ title=>'"ID страницы (часть URL; используется в ссылках на эту страницу)"', mapto=>'page_id'},
		{ title=>'Цена', mapto=>'price'},
		{ title=>'Название вида налогов', mapto=>'tax_type', default=>''},
		{ title=>'Скрытый', mapto=>'invisible', default=>'0'},
		{ title=>'Можно купить', mapto=>'available', default=>'1'},
		{ title=>'Старая цена', mapto=>'regular_price'},
		{ title=>'На складе', mapto=>'none', default=>'1'},
		{ title=>'Продано', mapto=>'sold', default=>'0'},
		
		{ title=>'Описание (English)', mapto=>'description_en'},
		{ title=>'Описание (Русский)', mapto=>'description', quote=>1},
		
		{ title=>'Краткое описание (English)', mapto=>'brief_description_en'},
		{ title=>'Краткое описание (Русский)', mapto=>'brief_description'},
		
		
		{ title=>'Сортировка', mapto=>'sort_order'},
		
		{ title=>'Заголовок страницы (English)', mapto=>'page_title_en'},
		{ title=>'Заголовок страницы (Русский)', mapto=>'page_title'},
		
		{ title=>'Тэг META keywords (English)', mapto=>'meta_keywords_en'},
		{ title=>'Тэг META keywords (Русский)', mapto=>'meta_keywords'},
		
		{ title=>'Тэг META description (English)', mapto=>'meta_description_en'},
		{ title=>'Тэг META description (Русский)', mapto=>'meta_description'},
		
		{ title=>'Стоимость упаковки', mapto=>'h_charge'},
		{ title=>'Вес продукта', mapto=>'weight'},
		{ title=>'Бесплатная доставка', mapto=>'free_shipping', dafault=>'0'},
		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'min_order_quantity', dafault=>'1'},
		{ title=>'Файл продукта', mapto=>'digital_filename'},
		{ title=>'Количество дней для скачивания', mapto=>'download_days', dafault=>'5'},
		{ title=>'Количество загрузок (раз)', mapto=>'downloads_number', dafault=>'5'},
		
		{ title=>'Фотография', mapto=>'picture_1', quote=>1},

		{ title=>'Артикул товара (Русский)', mapto=>'code1' },
		{ title=>'IP (Русский)', mapto=>'IP' },
		{ title=>'Арматура (Русский)', mapto=>'Armature' },
		{ title=>'Высота (Русский)', mapto=>'Height' },
		{ title=>'Высота встраиваемой части (Русский)', mapto=>'HeightOfInnerPart' },
		{ title=>'Глубина (Русский)', mapto=>'Depth' },
		{ title=>'Диаметр (Русский)', mapto=>'Diameter' },
		{ title=>'Диаметр врезного отверстия (Русский)', mapto=>'InnerDiameter' },
		{ title=>'Длина (Русский)', mapto=>'Length' },
		{ title=>'Класс защиты (Русский)', mapto=>'ProtectionClass' },
		{ title=>'Лампы (Русский)', mapto=>'Lamps' },
		{ title=>'Производство (Русский)', mapto=>'Production' },
		{ title=>'Тип цоколя (Русский)', mapto=>'LampBaseType' },
		{ title=>'Фабрика (Русский)', mapto=>'Vendor' },
		{ title=>'Ширина (Русский)', mapto=>'Width' },
		{ title=>'Категория (Русский)', mapto=>'categoryname' },
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	my @quotes;
	my @forcedquotes;
	foreach my $column (@all_columns_ru){
		
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
		push @defaults, exists $column->{default} ? $column->{default} : '';
		push @quotes, exists $column->{quote} ? $column->{quote} : 0;
		push @forcedquotes, exists $column->{force_quote} ? $column->{force_quote} : 0;
	}
	
	my $glue_char = ";";
	
	my @output;
	
	# make header
	push @output, join ($glue_char, @header_list);
	
	# process data
	my $col_number = @map_list;
	
	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my $suppress_defaults = $dataitem->{suppress_defaults} ? 1 : 0;
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = exists $dataitem->{$key} ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			my $quote = $quotes[$cn];
			my $force_quote = $forcedquotes[$cn];
			
			$value =~ s/"/""/g; #";
			
			if($force_quote || ($value ne '')){
				if ($force_quote || $quote || $value =~ /$glue_char/o ){
					$value = '"' . $value . '"';
				}
			}
			
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	
	return \@output;
	
}

sub category_thumb {
	my $storename = shift;
	# create Resizer
	my $resize = Image::Resize->new( $storename );
	my $width = $resize->width();
	my $height = $resize->height();
	my $gd;
	# small thumbnail
	if($width > 100 || $height > 100){
		$gd = $resize->resize(100, 100);
	} else {
		$gd = $resize->gd();
	}
	open XX, ">$storename" or die "!!v";
	binmode XX;
	print XX $gd->jpeg();
	close XX;
}

