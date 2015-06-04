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


# initialization

our $CAT_LIMIT   = 0;
our $PROD_LIMIT  = 0;

our $prefix = 'ilc';
our $article_mask = $prefix . '-%05d';

our $verbose_top_categories = 1;
our $verbose_categories = 1;
our $verbose_products = 1;


our $src_product_pictures = $constants{SourceFiles}{PRODUCT_PICTURES};
our $src_vendor_pictures = $constants{SourceFiles}{VENDOR_PICTURES};
our $csv_dir = $constants{DestinationFiles}{CSV_DIR};
our $output_pictures = $constants{DestinationFiles}{PRODUCT_PICTURES};

our $convert = $constants{ImageMagick}{CONVERT};

unless (-e $csv_dir && -d $csv_dir){
	mkpath($csv_dir);
}

unless (-e $output_pictures && -d $output_pictures){
	mkpath($output_pictures);
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
	
	my $counter = $CAT_LIMIT;
	foreach my $topitem (@toplist){
		process_category($topitem, \@collector, '');
		print "Top category processed\n" if $verbose_top_categories;
		if($CAT_LIMIT){
			last unless --$counter;
		}
	}
	
	save_csv("$csv_dir/full.csv", \@collector, 'utf-8');
	
}

sub process_category {
	my ($category, $collector, $spacer) = @_;
	
	my $cat_id = $category->ID;
	
	print "Process category $cat_id\n" if $verbose_categories;
	
	my $catname = $category->Name;
	$catname =~ s/\r|\n|\t/ /g;
	
	my $name = $spacer.$catname;

	my %h = (
		name => $name,
		suppress_defaults => 1,
	);

	push @$collector, \%h;
	
	process_products($category, $collector);

	my @sublist = $category->getCategories($dbh);
	foreach my $item (@sublist){
		process_category($item, $collector, $spacer.'!');
	}
	
}

sub process_products {
	my ($category, $collector) = @_;
	my @prodlist = $category->getProducts($dbh, $PROD_LIMIT);
	process_product($_, $collector) foreach @prodlist;
}


sub process_product {
	my($product, $collector) = @_;
	
	my $product_id = $product->ID;
	
	print "Process product $product_id\n" if $verbose_products;
	
	my @pics = $product->getProductPictures($dbh);

	
	my $price = int($product->get('Price') * 0.99);

	my $descr = $product->get('Description');

	my $name = $product->Name;
	$name=~s/^\s+//;
	$name=~s/\s+$//;
	
	my %h = (
		code => $product->get('InternalID'),
		name => $name,
		price => $price,
		description => $product->get('Description'),
		brief_description => $product->get('ShortDescription'),
	);
		
	my $picnumber = 1;
	foreach my $pic_obj (@pics){
		
		my $safe_name = $pic_obj->ID;
		
		my $small_name = "${safe_name}_thm.jpg";
		my $medium_name = "${safe_name}.jpg";
		my $org_name = "${safe_name}_enl.jpg";
		
		unless(-e "$output_pictures/$org_name"){
			# image does not exist, do convertation
			
			my $pic_id = $pic_obj->ID;
			my $src = $pic_obj->getStoragePath();
			
			# resize to 300x300
			my $cmd = "$convert -resize \"300x300>\" \"$src\" \"$output_pictures/$medium_name\"";
			`$cmd`;

			# resize to 150x150
			$cmd = "$convert -resize \"150x150>\" \"$src\" \"$output_pictures/$small_name\"";
			`$cmd`;

			# make the original picture JPEG anyway
			$cmd = "$convert \"$src\" \"$output_pictures/$org_name\"";
			`$cmd`;

		}
		
		# store into the product's info
		$h{"picture_".$picnumber++} = "$medium_name,$small_name,$org_name";
		
		last;
	}
	
	push @$collector, \%h;
	
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
		
		{ title=>'Тэг META keywords (English)', mapto=>'none'},
		{ title=>'Тэг META keywords (Русский)', mapto=>'none'},
		
		{ title=>'Тэг META description (English)', mapto=>'none'},
		{ title=>'Тэг META description (Русский)', mapto=>'none'},
		
		{ title=>'Стоимость упаковки', mapto=>'h_charge'},
		{ title=>'Вес продукта', mapto=>'weight'},
		{ title=>'Бесплатная доставка', mapto=>'free_shipping', dafault=>'0'},
		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'min_order_quantity', dafault=>'1'},
		{ title=>'Файл продукта', mapto=>'digital_filename'},
		{ title=>'Количество дней для скачивания', mapto=>'download_days', dafault=>'5'},
		{ title=>'Количество загрузок (раз)', mapto=>'downloads_number', dafault=>'5'},
		
		{ title=>'Фотография', mapto=>'picture_1', quote=>1},

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

