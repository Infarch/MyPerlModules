use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use utf8;

use File::Path;
use File::Copy;
use Image::Resize;
use Error ':try';
use URI::Escape;
use Encode;
use FindBin;

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;
use ProductDescriptionPicture;
use Advice;
use Translit;


my $pp_subcat = "new_pm";
my $cp_subcat = "";

my $output_dir = 'z:/P_FILES/samuil/prosmebel.ru/output';

my $output_product_pictures = "z:/P_FILES/samuil/prosmebel.ru/output/products_pictures";
$output_product_pictures .= "/$pp_subcat" if $pp_subcat;
my $output_category_pictures = "z:/P_FILES/samuil/prosmebel.ru/output/products_pictures";
$output_category_pictures .= "/$cp_subcat" if $cp_subcat;

my $output_colors = 'z:/P_FILES/samuil/prosmebel.ru/output/products_colors';
my $output_modules = 'z:/P_FILES/samuil/prosmebel.ru/output/products_modules';
my $output_descriptions = 'z:/P_FILES/samuil/prosmebel.ru/output/products_descriptions';
my $output_upholstery = 'z:/P_FILES/samuil/prosmebel.ru/output/products_upholstery';
my $output_scv = 'z:/P_FILES/samuil/prosmebel.ru/output/csv';
my $output_html = 'z:/P_FILES/samuil/prosmebel.ru/output/html';


my $target_location = '/published/publicdata/MEBELI84SHCM/attachments/SC';
#my $target_location = '..';

my @collector;

my %vendors;

my $verbose_categories = 0;
my $verbose_category_pictures = 0;
my $verbose_products = 1;
my $verbose_upholsteries = 0;

my $IN_TEST = 0;
my $product_limit = 0;
my $products_per_file = 0; # actually, products and categories



# create directories
unless (-e $output_dir && -d $output_dir){
	mkpath($output_dir);
}
unless (-e $output_product_pictures && -d $output_product_pictures){
	mkpath($output_product_pictures);
}
unless (-e $output_category_pictures && -d $output_category_pictures){
	mkpath($output_category_pictures);
}
unless (-e $output_colors && -d $output_colors){
	mkpath($output_colors);
}
unless (-e $output_modules && -d $output_modules){
	mkpath($output_modules);
}
unless (-e $output_scv && -d $output_scv){
	mkpath($output_scv);
}
unless (-e $output_descriptions && -d $output_descriptions){
	mkpath($output_descriptions);
}
#unless (-e $output_html && -d $output_html){
#	mkpath($output_html);
#}
unless (-e $output_upholstery && -d $output_upholstery){
	mkpath($output_upholstery);
}

# copy css file for testing purposes
copy("$FindBin::Bin/isoft.css", "$output_dir/isoft.css");

# get database handler
my $dbh = get_dbh();


# mark all products as not exported yet
ISoft::DB::do_query($dbh, sql=>"update `product` set `exported`=0");
$dbh->commit();

my $files_count = 555;

my $done = 0;
while( !$done ){
	$done = do_output();
	if(@collector > 0){
		my $idx = sprintf("%02d", $files_count++);
		
		foreach my $x (@collector){
			if($x->{description_0}){
				$x->{description_0} =~ s/\r\n|\r|\n|\t/ /g;
			}
			if($x->{description_1}){
				$x->{description_1} =~ s/\r\n|\r|\n|\t/ /g;
			}
		}

		$_->{description} = $_->{description_1} foreach (@collector);
		save_csv("$output_scv/edit_$idx.csv", get_production_columns(), \@collector);
		$_->{description} = $_->{description_0} foreach (@collector);
		save_csv("$output_scv/import_$idx.csv", get_production_columns(), \@collector);
		@collector = ();
	}
}

release_dbh($dbh);

exit;


##############################################################################################

# generates files for importing into webassyst (one file for one call!!!).
# returns true if all products have been processed.
# false means that some products have been skipped due to file size (or any other) limitation.
# if so, just call the function againt to start a new file generating.
sub do_output {
	# get root
	my $rc_obj = get_root();
	$rc_obj->set("Name", "TEST") if $IN_TEST;
	return 0 unless process_category($rc_obj); # not all products have been exported, so we can skip other steps
	# just append upholsteries to the current file regardless of limitations
	process_upholsteries();
	return 1;
}

# collects a product. in case of meet any pre-defined limitation returns false.
sub push_product {
	push @collector, $_[0];
	return 1 unless $products_per_file;
	return @collector < $products_per_file;
}

# returns true if the products have been processed without any limitations.
# false means that the product have been processed but some limitation happened
sub process_product {
	my ($cat_obj, $prod_obj) = @_;
	
	print "Product ".$prod_obj->ID."\n" if $verbose_products;
	
	my $name = $prod_obj->Name;
	$name =~ s/^\s+//;
	$name =~ s/\s+$//;
	
	my $code = sprintf 'PM-%05d', $prod_obj->ID;
	
	my %h = (
		name => $name,
		code => $code,
	);
	
	populate_meta(\%h, $prod_obj);	
	
	# photos
	add_product_photos($prod_obj, \%h);
	
	my $price = price( $prod_obj->get("Price") );
	$h{price} = $price if $price;
	
	# build description (this function can override some params so it should be called at the end)
	build_description($cat_obj, $prod_obj, \%h);
	
	# mark as exported
	$prod_obj->set("Exported", 1);
	$prod_obj->update($dbh);
	$dbh->commit();
	
	# push to the collector
	return push_product(\%h);
}

sub build_description {
	my ($cat_obj, $prod_obj, $h) = @_;
	
	my $ca = $cat_obj->getAlias();
	my $pa = $prod_obj->getAlias();
	
	# back to catalogue
	my $backlink = "<a href='/category/$ca'>Выбрать другую серию...</a><br/><br/>";
	
	# phone
	my $phone = "<div class='q_phone'>Телефон для справок и консультаций: +7 (495) 920-48-24</div>";
	
	# the Beginning link
	my $beginning = "<a class='up' href='/product/$pa/#beginning'>↑ Наверх</a>";
	
	# colors
	my $colorblock = "";
	my (@mains, @seconds);
	foreach my $color_obj ( $prod_obj->getColors($dbh) ){
		my $data = "";
		my $name = $color_obj->Name();
		if(my $pic_obj = $color_obj->getPicture($dbh)){
			my $file = "color_" . $pic_obj->getNameToStore();
			my $path = "$output_colors/$file";
			copy($pic_obj->getStoragePath(), $path) unless -e $path;
			$data .= "<img width='50' height='50' src='$target_location/products_colors/$file' title='$name'/>";
		}
		$data .= "<h3 class='name'>$name</h3>";
		if($color_obj->get("Type")==1){
			push @seconds, $data;
		}else{
			push @mains, $data;
		}
	}
	
	# upholsteries become products :(
	my @upholsteries;
	my @uph_list = $prod_obj->getUpholsteries($dbh);
	print scalar @uph_list, " upholsteries\n" if $verbose_upholsteries;
	foreach my $upholstery_obj (@uph_list){
		my $upholstery_name = $upholstery_obj->Name();
		my ($upcolor_obj) = $upholstery_obj->getColors($dbh, 1);
		my $ua = $upholstery_obj->getAlias();
		my $file = $upcolor_obj->getNameToStore();
		my $path = "$output_upholstery/$file";
		copy($upcolor_obj->getStoragePath(), $path) unless -e $path;
		
		# add the first image to the overview
		my $data .= "<a href='/product/$ua' target='_blank'><img width='50' height='50' src='$target_location/products_upholstery/$file' title='$upholstery_name'/></a>";
		$data .= "<h3 class='name'><a href='/product/$ua' target='_blank'>$upholstery_name</a></h3>";
		push @upholsteries, $data;
	}
	
	# build the color/upholstery block
	foreach my $item ( 
		["Основные цвета:", \@mains], 
		["Дополнительные цвета:", \@seconds], 
		["Варианты обивки:", \@upholsteries] 
	){
		if( @{$item->[1]} ){
			my $sectionheader = $item->[0];
			my $section = "<h2>$sectionheader</h2><hr/><ul class='product_color_list'>";
			$section .= "<li>$_</li>" foreach @{$item->[1]};
			$section .= "</ul><br/>";
			$colorblock .= $section;
		}
	}
	
	my %pricecache;
	
	# price list area
	my $first_price;
	my $price_ref = "";
	my $price_block_head = "";
	my $price_block_body = "";
	my @chapters = $prod_obj->getModuleChapters($dbh);
	if(@chapters){
		$price_ref = "<div class='pricelist'><a href='/product/$pa/#pricelist'>Прайс-лист</a></div>";
		$price_block_head .= "<a name='pricelist'>Прайс-лист</a><br/><div class='price_panel'><ul class='price_menu'>";
		foreach my $chapter_obj ($prod_obj->getModuleChapters($dbh)){
			my $chapter_name = $chapter_obj->Name;
			#my $chapter_alias = Translit::convert($chapter_name, '_');
			my $chapter_alias = uri_escape_utf8($chapter_name);
			$price_block_head .= "<li><a href='/product/$pa/#$chapter_alias'>$chapter_name</a></li>";
			
			$price_block_body .= "<a name='$chapter_alias'> </a><div class='price_caption'>$chapter_name</div><hr/><ul class='product_list'>";
			
			foreach my $module_obj ($chapter_obj->getModules($dbh)){
				my $name = $module_obj->Name;
				my $sku = $module_obj->get("Art_No");
				$sku =~ s/'/`/g; #' do not break the title attribute quotes
				my $size = $module_obj->get("Size");
				my $price = price($module_obj->get("Price"));
				$first_price = $price unless $first_price;
				$pricecache{$sku} = $price;
				
				my $picture = "";
				if( my $pic_obj = $module_obj->getModulePicture($dbh) ){
					my $file = $pic_obj->getNameToStore();
					my($name, $ext) = split '\.', $file;
					$name = $pa . '-' . Translit::convert( safe_name( $sku ), "_"); # to FILE NAME
					my $uname = uri_escape_utf8($name); # to FILE URL
					my $path = "$output_modules/$name.$ext";
					unless(-e $path){
						copy($pic_obj->getStoragePath(), $path) or die "Cannot copy $file to $path: $!";
					}
					
					$picture = "<img src='$target_location/products_modules/$uname.$ext' title='$sku'/>";
				}
				
				my $cl = "";
				my @colors = $module_obj->getModuleColors($dbh);
				if(@colors){
					$cl .= "<select class='color'>";
					foreach my $color_obj (@colors){
						my $cname = $color_obj->Name;
						my $code = $color_obj->get("Code");
						$cl .= "<option value='$code'>$cname</option>";
					}
					$cl .= "</select>";
				}
				
				$price_block_body .= "<li><span class='title'>$name</span><div class='img'>$picture</div>";
				$price_block_body .= "$cl<div class='param'>Артикул: $sku</div><div class='param'>Размер: $size</div>";
				$price_block_body .= "<div class='price'>$price руб.</div></li>";
				
			}
			
			$price_block_body .= "</ul><br/><br/>$beginning<br/><br/>";
		}
		$price_block_head .= "</ul></div><br/>";
	}
	
	
	# complex table
	my $table = "";
	my @tblist = $prod_obj->getTableData($dbh);
	if(@tblist){
		my $price = 0;
		$table .= "<table class='mincomplect'><tr><th>Наименование модели</th><th>артикул</th><th>размер</th><th>цена(руб.)</th></tr>";
		foreach my $obj (@tblist){
			my $name = $obj->Name;
			my $sku = $obj->get("Art_No");
			my $size = $obj->get("Size");
			die "No price ($sku)" unless exists $pricecache{$sku};
			# take the price from other table because the table itself contains wrong values sometimes
			my $pr = $pricecache{$sku};
			$table .= "<tr><td>$name</td><td>$sku</td><td>$size</td><td>$pr</td></tr>";
			$price += $pr;
		}
		$table .= "<tr><td colspan='4' align='right'><b>Итого: $price руб.</b></td></tr></table>";
	}

	# advices
	my $advices = "";
	my @adv_list = $prod_obj->getAdvices($dbh);
	if(@adv_list){
		$advices .= "<div class='recommend_offers'><p>Наши рекомендации</p><ul class='recommend_list'>";
		foreach my $advice_obj (@adv_list){
			my $tpa_obj = Product->new;
			$tpa_obj->set("ID", $advice_obj->get("AdvicedProduct_ID"));
			$tpa_obj->markDone();
			next unless $tpa_obj->checkExistence($dbh);
			
			my $name = $advice_obj->Name;
			my $org_name = $tpa_obj->Name();
			my $alias = $tpa_obj->getAlias();
			
#			if($org_name =~ /^(Мебель для руководителя) (.+)/i){
#			}
			
			my $thumb = "${alias}_th_1.jpg";
			#my $t_href = "$target_location/products_pictures/$thumb";
			my $t_href = "$target_location/products_pictures/";
			$t_href .= "$pp_subcat/" if $pp_subcat;
			$t_href .= $thumb;
			
			my $p_href = "/product/$alias";
			$advices .= "<li><span class='title'><a title='$name' href='$p_href'>$name</a></span>";
			$advices .= "<div class='img'><a title='$name' href='$p_href'><img src='$t_href' alt='$name'/></a></div>";
			$advices .= "</li>";
		}
		$advices .= "</ul></div><br/>$beginning<br/><br/>";
	}
	
	# build two descriptions - the first one is for editing while the second is for importing
	foreach my $editmode (1, 0){
		my $d = "<a name='beginning'> </a>";
		$d .= $price_ref;
		$d .= $backlink;
		$d .= $colorblock;
		$d .= parse_description($prod_obj->get("Description2")); # if $editmode;
		$d .= $phone;
		$d .= $table;
		$d .= "<br/>";
		$d .= parse_description($prod_obj->get("Description")) if $editmode;
		$d .= "<br/>";
		$d .= $price_block_head;
		$d .= $price_block_body;
		$d .= $advices;
		$h->{"description_$editmode"} = $d;
	}
	
	my $bd = "";
	if(my $avail = $prod_obj->get("Avail")){
		$bd .= "$avail<br/>";
	}
	$bd .= "Уточняйте у менеджера<br/>";
	if($first_price){
		$bd .= "Цены от:";
		$h->{price} = $first_price;
	}
	$h->{brief_description} = $bd;
	
}

sub parse_description {
	my $text = shift;
	
	return "" unless $text;
	
	if($text =~ /Производство:\s*(\w+)/i){
		$vendors{$1}++;
	}
	
	my %hh;
	
	while($text =~ /src="(\d+)"/g){
		my $id = $1;
		my $obj = ProductDescriptionPicture->new;
		$obj->set("ID", $1);
		$obj->select($dbh);
		my $filename = $obj->get("Local_Filename");
		my $path = $output_descriptions . "/$filename";
		my $url = "$target_location/products_descriptions/$filename";
		unless(-e $path){
			copy($obj->getStoragePath(), $path);
		}
		$hh{$id} = $url;
	}
	
	$text =~ s/src="(\d+)"/src="$hh{$1}"/g;
	return $text;
}

sub add_product_photos {
	my($prod_obj, $h) = @_;
	
	my $count = 1;
	foreach my $pic_obj ($prod_obj->getProductPictures($dbh)){
		
		my $path = $pic_obj->getStoragePath();
		my $alias = $prod_obj->getAlias();
		
		my $med = "${alias}_med_$count.jpg";
		my $thumb = "${alias}_th_$count.jpg";
		my $org = "${alias}_org_$count.jpg";
		
		my $path_med = $output_product_pictures . '/' . $med;
		my $path_thumb = $output_product_pictures . '/' . $thumb;
		my $path_org = $output_product_pictures . '/' . $org;
		
		# check existence
		unless(-e $path_org){
			# do transformations
			try {
				# create Resizer
				my $resize = Image::Resize->new( $path );
				my $width = $resize->width();
				my $height = $resize->height();
				my $gd;
				# small thumbnail
				if($width > 150 || $height > 150){
					$gd = $resize->resize(150, 150);
				} else {
					$gd = $resize->gd();
				}
				open XX, ">$path_thumb" or die "!!v1";
				binmode XX;
				print XX $gd->jpeg();
				close XX;

				# medium
				if($width > 300 || $height > 300){
					$gd = $resize->resize(300, 300);
				} else {
					$gd = $resize->gd();
				}
				open YY, ">$path_med" or die "!!v2";
				binmode YY;
				print YY $gd->jpeg();
				close YY;
				
				# original
				$gd = $resize->gd();
				open ZZ, ">$path_org" or die "!!v3";
				binmode ZZ;
				print ZZ $gd->jpeg();
				close ZZ;

			} otherwise {
				die "Image $path caused an exception\n";
			};
		}
		
		if($pp_subcat){
			$med = "$pp_subcat/$med";
			$thumb = "$pp_subcat/$thumb";
			$org = "$pp_subcat/$org";
		}
		
		$h->{"picture_".$count++} = "$med,$thumb,$org";
	}
	
}

sub make_category_picture {
	my ($cat_obj) = @_;

	my $pic_file = 'catalog_pm'.$cat_obj->ID().'.jpg';
	my $path_name = "$output_category_pictures/$pic_file";
	
	unless( -e $path_name ){
		my $path;
		if(my $cpic_obj = $cat_obj->getCategoryPicture($dbh)){
			$path = $cpic_obj->getStoragePath();
		}else{
			# take a product picture instead
			my @rlist = ($cat_obj);
			while( my $c1_obj = shift @rlist ){
				# has products?
				my @products = $c1_obj->getProducts($dbh);
				if(@products){
					foreach my $prod_obj (@products){
						my @pictures = $prod_obj->getProductPictures($dbh);
						if(my $pic_obj = shift @pictures){
							$path = $pic_obj->getStoragePath();
							last;
						}
					}
					last if $path;
				}else{
					# add sub categories to the lookup list
					push @rlist, $c1_obj->getCategories($dbh);
				}
			}
		}
		
		die "no category picture ".$cat_obj->ID unless $path;
		
		try {
			# create Resizer
			my $resize = Image::Resize->new( $path );
			my $width = $resize->width();
			my $height = $resize->height();
			my $gd;
			# small thumbnail
			if($width > 100 || $height > 100){
				$gd = $resize->resize(100, 100);
			} else {
				$gd = $resize->gd();
			}
			open XX, ">$path_name" or die "!!v";
			binmode XX;
			print XX $gd->jpeg();
			close XX;
			
		} otherwise {
			die "Image $path caused an exception\n";
		};
	}
	
	if($cp_subcat){
		$pic_file = "$cp_subcat/$pic_file";
	}
	return $pic_file;
	
}

sub populate_meta {
	my($reff, $obj) = @_;
	$reff->{page_title} = $obj->get("PageTitle");
	$reff->{meta_keywords} = $obj->get("PageMetakeywords");
	$reff->{meta_description} = $obj->get("PageMetaDescription");
	$reff->{page_id} = $obj->getAlias();
}

sub process_upholsteries {
	my $spacer = $IN_TEST ? '!' : '';
	
	my %h = (
		name => "${spacer}Материалы",
		suppress_defaults => 1,
		page_id => "materialy",
	);
	push @collector, \%h;
	
	# get all upholsteries
	my @list = Upholstery->new()->selectAll($dbh);
	
	foreach my $upholstery_obj (@list){
		
		print "Upholstery ".$upholstery_obj->getAlias()."\n" if $verbose_products;
		
		my $upholstery_name = $upholstery_obj->Name;
		$upholstery_name =~ s/^\s+//;
		$upholstery_name =~ s/\s+$//;
		
		my $code = sprintf 'PM-UPH-%05d', $upholstery_obj->ID;
		
		
		# build description
		my $description = "<p>Покрытие $upholstery_name</p><br/><ul style='list-style:none outside none;margin:0;padding:0;'>";
		
		my @colors = $upholstery_obj->getColors($dbh);
		foreach my $upcolor_obj (@colors){
			my $color_name = $upcolor_obj->Name;
			my $file = $upcolor_obj->getNameToStore();
			my $path = "$output_upholstery/$file";
			my $src = "$target_location/products_upholstery/$file";
			copy($upcolor_obj->getStoragePath(), $path) unless -e $path;
			
			$description .= "<li style='display:inline-block;margin:10px'><span style='color: #B85D28;display: table-cell;text-align: center;text-transform: uppercase;margin: 0 0 5px 0;'>$color_name</span>";
			$description .= "<img src='$src' alt='$color_name'/>";
			$description .= "</li>";
		}
	
		$description .= "</ul><br/>";
		
		my %h1 = (
			name => "Покрытие $upholstery_name",
			code => $code,
			page_id => $upholstery_obj->getAlias(),
			description_1 => $description,
			description_0 => $description,
		);
		
		push @collector, \%h1;
	}
}

# returns true if all products have been processed.
# false means that some products have been skipped due to file size (or any other) limitation.
sub process_category {
	my ($cat_obj) = @_;
	
	my $cid = $cat_obj->ID;
	my $level = $cat_obj->get("Level");
	
	print "Category $cid (level $level)\n" if $verbose_categories;
	
	# get the category picture
	my $category_picture = make_category_picture($cat_obj) if $level; # the root does not need pictures
	print "No Category Picture\n" unless $category_picture;
	
	my $catname = $cat_obj->Name;
	$catname =~ s/\r|\n|\t/ /g;
	
	$level++ if $IN_TEST;
	
	my $spacer = $level ? '!' x ($level - 1) : '';
	
	my $name = $spacer.$catname;

	my %h = (
		name => $name,
		suppress_defaults => 1,
		picture_1 => $category_picture,
	);

	populate_meta(\%h, $cat_obj);	
	push @collector, \%h if $IN_TEST || $level;
	
	foreach my $prod_obj ($cat_obj->getUnexportedProducts($dbh, $product_limit)){
		return 0 unless process_product($cat_obj, $prod_obj);
	}
	foreach my $c1_obj ($cat_obj->getCategories($dbh)){
		return 0 unless process_category($c1_obj);
	}
	return 1;
}

sub get_root {
	my $rc_obj = Category->new;
	$rc_obj->set("Level", 0);
	$rc_obj->select($dbh);
	return $rc_obj;
}

sub get_production_columns {
	my $columns = [
		{ title=>'Артикул', mapto=>'code', quote=>1},
		{ title=>'Наименование (Русский)', mapto=>'name'},
		{ title=>'Наименование (English)', mapto=>'name_en'},
		{ title=>'"ID страницы (часть URL; используется в ссылках на эту страницу)"', mapto=>'page_id'},
		{ title=>'Цена', mapto=>'price'},
		{ title=>'Название вида налогов', mapto=>'tax_type', default=>''},
		{ title=>'Скрытый', mapto=>'invisible', default=>'0'},
		{ title=>'Можно купить', mapto=>'available', default=>'1'},
		{ title=>'Старая цена', mapto=>'regular_price'},
		
		{ title=>'Продано', mapto=>'sold', default=>'0'},
		{ title=>'Описание (Русский)', mapto=>'description', quote=>1},
		{ title=>'Описание (English)', mapto=>'description_en'},
		{ title=>'Краткое описание (Русский)', mapto=>'brief_description'},
		{ title=>'Краткое описание (English)', mapto=>'brief_description_en'},
		
		{ title=>'Сортировка', mapto=>'sort_order'},
		
		{ title=>'Заголовок страницы (Русский)', mapto=>'page_title'},
		{ title=>'Заголовок страницы (English)', mapto=>'page_title_en'},
		
		{ title=>'Тэг META keywords (Русский)', mapto=>'meta_keywords'},
		{ title=>'Тэг META keywords (English)', mapto=>'meta_keywords_en'},
		
		{ title=>'Тэг META description (Русский)', mapto=>'meta_description'},
		{ title=>'Тэг META description (English)', mapto=>'meta_description_en'},
		
		{ title=>'Стоимость упаковки', mapto=>'h_charge'},
		{ title=>'Вес продукта', mapto=>'weight'},
		
		{ title=>'Бесплатная доставка', mapto=>'free_shipping', dafault=>'0'},
		
		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'min_order_quantity'},
		
		{ title=>'Файл продукта', mapto=>'digital_filename'},
		
		{ title=>'Количество дней для скачивания', mapto=>'download_days'},
		
		{ title=>'Количество загрузок (раз)', mapto=>'downloads_number'},
		
		{ title=>'Фотография', mapto=>'picture_1', quote=>1},
		{ title=>'Фотография', mapto=>'picture_2', quote=>1},
		{ title=>'Фотография', mapto=>'picture_3', quote=>1},
		{ title=>'Фотография', mapto=>'picture_4', quote=>1},
		{ title=>'Фотография', mapto=>'picture_5', quote=>1},
		{ title=>'Фотография', mapto=>'picture_6', quote=>1},
		{ title=>'Фотография', mapto=>'picture_7', quote=>1},
		{ title=>'Фотография', mapto=>'picture_8', quote=>1},
		{ title=>'Фотография', mapto=>'picture_9', quote=>1},
		{ title=>'Фотография', mapto=>'picture_10', quote=>1},
		{ title=>'Фотография', mapto=>'picture_11', quote=>1},
		{ title=>'Фотография', mapto=>'picture_12', quote=>1},
		
#		{ title=>'Покрытие (Русский)', mapto=>'cover' },
#		{ title=>'Покрытие (English)', mapto=>'cover_en' },
#		{ title=>'Цвет (Русский)', mapto=>'color'},
#		{ title=>'Цвет (English)', mapto=>'color_en'},
#		{ title=>'Производитель (Русский)', mapto=>'vendor'},
#		{ title=>'Производитель (English)', mapto=>'vendor_en'},
#		{ title=>'Срок доставки (Русский)', mapto=>'ship_term'},
#		{ title=>'Срок доставки (English)', mapto=>'ship_term_en'},
	
	];	
	return $columns;
}

sub get_edit_columns {
	my $columns = [
		{ title=>'Object', mapto=>'object'},
		{ title=>'OID', mapto=>'id'},
		{ title=>'Name', mapto=>'name'},
		{ title=>'Title', mapto=>'title', default=>''},
		{ title=>'MetaKeywords', mapto=>'kw', default=>''},
		{ title=>'MetaDescription', mapto=>'ds', default=>''},
	];	
	return $columns;
}

sub csv_provider {
	my ($columns, $data_ref) = @_;
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	my @quotes;
	my @forcedquotes;
	foreach my $column (@$columns){
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
			my $value = exists $dataitem->{$key} && defined $dataitem->{$key} ?
				$dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			$value =~ s/&lt;/</g;
			$value =~ s/&gt;/>/g;
			$value =~ s/&quot;/"/g; #"
			# remove spare quotes and escape
			$value =~ s/"+/'/g; #";
			my $quote = $quotes[$cn];
			my $force_quote = $forcedquotes[$cn];
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

sub save_csv {
	my ($name, $columns, $data_ref) = @_;
	my $result_ref = csv_provider($columns, $data_ref);
	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";
	foreach my $line (@$result_ref){
		utf8::encode($line);
		#$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	close CSV;
}

sub safe_name {
	my $name = shift;
	# remove unsafe characters
	$name =~ s/['\/?<>\\:*|"%]/_/g; #'
	# replace all unusual space characters by correct one
	$name =~ s/\s+/ /g;
	# remove leading spaces
	$name =~ s/^\s+//;
	# remove trailing spaces and periods
	$name =~ s/[\s.]+$//;
	return $name;
}

sub price {
	my $val = shift;
	return undef unless defined $val;
	return int($val * .96);
}