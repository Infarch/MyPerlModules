use strict;
use warnings;

use utf8;

use File::Copy;
use LWP::UserAgent;
use Encode qw/encode decode/;

use lib ("/work/perl_lib", "local_lib");

use ISoft::DBHelper;

# Members
use Category;
use Product;

my $limit = 0;

my $out_dir = 'output';
my $out_csv = "$out_dir/data.csv";

my $out_cp = "$out_dir/categories_pictures";
my $out_pp = "$out_dir/products_pictures";

my $agent = LWP::UserAgent->new;

my $dbh = get_dbh();

# get categories
my $tmp_cat_obj = Category->new();
$tmp_cat_obj->set('Level', 1);
$tmp_cat_obj->setOrder('Name', 'asc');

my @cat_list = $tmp_cat_obj->listSelect($dbh);


my @data;

my $char = '';

my $count = 0;

foreach my $category_obj (@cat_list){

	my $cat_name = $category_obj->Name();
	
	print $cat_name, "\n";
	
	my $new_char = substr $cat_name, 0, 1;
	if($new_char ne $char){
		$char = $new_char;
		push @data, {name=>$char};
	}
	
	# check whether the category has description
	my $descr = $category_obj->get('Description');
	
	unless( defined $descr ){
		print "No description for $cat_name, fetching\n";
		$category_obj->get("URL") =~ /fid=(\d+)/;
		my $url = "http://www.100aromatov.ru/fabricator/?id=$1";
		$descr = fetch_description($url);
		$category_obj->set("Description", $descr);
		$category_obj->update($dbh);
		$dbh->commit();
	}
	
	# get picture
	my $cat_pic_obj = $category_obj->getPicture($dbh);
	my $cp_name = '';

	if(!$cat_pic_obj->isFailed()){
		# copy file
		my $path = $cat_pic_obj->getStoragePath();
		$cp_name = 'cp_' . $category_obj->ID . '.jpg';
		copy($path, "$out_cp/$cp_name") or die "Copy failed: $!";
	}
	
	push @data, {name=>"!$cat_name", picture_1=>$cp_name, description=>$descr};
	
	# process products
	
	my @products = $category_obj->getProducts($dbh);
	foreach my $product_obj (@products){
		
		my $prod_name = $product_obj->Name;
		my $prod_description = $product_obj->get("Description");
		if($prod_description eq ' <br /><br /><br />'){
			$prod_description = '';
		}
		
		my $prod_photo = '';
		my @prod_photos = $product_obj->getProductPictures($dbh);
		if(@prod_photos > 0){
			my $path = $prod_photos[0]->getStoragePath();
			$prod_photo = 'pp_' . $product_obj->ID . '.jpg';
			copy($path, "$out_pp/$prod_photo") or die "Copy failed: $!";
		}
		
		# parse children
		my @type_list;
		my @form_list;
		my @size_list;
		my @price_list;
		my @existence_list;
		
		my $for_sale = $product_obj->get("ForSale");
		my @rows = $for_sale=~/<tr bgcolor="#E6E6E6">(.+?)<\/tr>/g;
		foreach my $row (@rows){
			my @cols = $row=~/<td.*?>(.+?)<\/td>/g;
			
			push @type_list, trim(strip_tags(shift @cols));
			
			my $formitem = strip_tags(shift @cols);
			$formitem=~s/\[\?\]//;
			push @form_list, trim($formitem);
			
			push @size_list, trim(shift @cols);
			
			my $priceitem = strip_tags(shift @cols);
			$priceitem=~s/\D//g;
			push @price_list, trim($priceitem);
			
			push @existence_list, trim(shift @cols);
			
		}
		
		my $type_str = '' . join ',', @type_list;
		my $form_str = '' . join ',', @form_list;
		my $size_str = '' . join ',', @size_list;
		my $price_str = '' . join ',', @price_list;
		my $existence_str = '' . join ',', @existence_list;
		
		
		# parse details
		
		my $year = '';
		my $author = '';
		my $designer = '';
		my $target = '';
		my $usage = '';
		my $group = '';
		my $contains = '';
		my $producted = '';
		my $similar = '';
		
		my $details = $product_obj->get("Details");
		
		if($details=~/<b>Год:<\/b> (.+?)<br \/>/){
			$year = $1;
		}
		
		if($details=~/<b>Парфюмер:<\/b> (.+?)<br \/>/){
			$author = $1;
		}

		if($details=~/<b>Дизайнер флакона:<\/b> (.+?)<br \/>/){
			$designer = $1;
		}

		if($details=~/<b>Назначение:<\/b> (.+?)<br \/>/){
			$target = $1;
		}

		if($details=~/<b>Применяется как:<\/b> (.+?)<br \/>/){
			$usage = strip_tags($1);
		}

		if($details=~/<b>Семейства:<\/b> (.+?)<br \/>/){
			$group = strip_tags($1);
		}

		if($details=~/<b>Содержит ноты:<\/b> (.+?)<br \/>/){
			$contains = strip_tags($1);
		}

		if($details=~/<b>Выпускается как:<\/b> (.+?)<br \/>/){
			$producted = strip_tags($1);
		}
		
		if($details=~/<b>Похожие ароматы:<\/b> (.+?)<br \/>/){
			$similar = strip_tags($1);
		}


		push @data, {
			name => $prod_name,
			description => $prod_description,
			picture_2 => $prod_photo,
			brand => $cat_name,
			
			type => $type_str,
			form => $form_str,
			size => $size_str,
			price => $price_str,
			existence => $existence_str,
			
			year => $year,
			author => $author,
			designer => $designer,
			target => $target,
			usage => $usage,
			group => $group,
			contains => $contains,
			producted => $producted,
			similar => $similar,
			
		};
		
		
	}
	
	
	
	if($limit && $count++>$limit){
		last;
	}
}



# save CSV
save_csv_cp($out_csv, \@data);







release_dbh($dbh);


# -------------------------------------

sub trim {
	my $str = shift;
	
	$str =~s/^\s+//;
	$str =~s/\s+$//;
	
	return $str;
}

sub strip_tags {
	my $str = shift;
	$str =~ s/<.+?>//g;
	return $str;
}

sub save_csv_cp {
	my ($name, $data_ref) = @_;
	my $result_ref = webassyst_provider($data_ref);
	
	open (CSV, '>', $name)
		or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
		$line = encode('cp1251', $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	close CSV;
}

sub webassyst_provider {

	my $data_ref = shift;
	
	# columns definition - custom CSV format
	
	my @all_columns_ru = (
		{ title=>'Наименование', mapto=>'name'},
		{ title=>'Описание', mapto=>'description', quote=>1},
		{ title=>'Фотография', mapto=>'picture_1'},
		{ title=>'Фотография', mapto=>'picture_2'},
		
		{ title=>'Тип', mapto=>'type'},
		{ title=>'Форма выпуска', mapto=>'form'},
		{ title=>'Объем', mapto=>'size'},
		{ title=>'Цена', mapto=>'price'},
		{ title=>'Наличие', mapto=>'existence'},
		
		{ title=>'Торговый дом', mapto=>'brand'},
		{ title=>'Год', mapto=>'year'},
		{ title=>'Парфюмер', mapto=>'author'},
		{ title=>'Дизайнер флакона', mapto=>'designer'},
		{ title=>'Назначение', mapto=>'target'},
		{ title=>'Применяется как', mapto=>'usage'},
		{ title=>'Семейства', mapto=>'group'},
		{ title=>'Содержит ноты', mapto=>'contains'},
		{ title=>'Выпускается как', mapto=>'producted'},
		{ title=>'Похожие ароматы', mapto=>'similar'},
		
		
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
		my $suppress_defaults = $dataitem->{suppress_defaults};
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = exists $dataitem->{$key} ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			my $quote = $quotes[$cn];
			my $force_quote = $forcedquotes[$cn];
			
			$value =~ s/"/""/g; #";
			
			
			if($force_quote){
				$value = '"' . $value . '"';
			} elsif ($quote && $value ne '') {
				$value = '"' . $value . '"';
			} elsif ( $value =~ /$glue_char/o ){
				$value = '"' . $value . '"';
			}
			
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	
	
	
	return \@output;
	
}

sub fetch_description {
	my $url = shift;
	
	my $descr = '';
	
	my $response = $agent->get($url);
	my $content = $response->decoded_content();
	if($content =~ /<img\sborder="0"\shspace="10"\salign="left"\svspace="10"\s
		src="http:\/\/www\.100aromatov\.ru\/showpic\.asp\?type=1&amp;id=\d+"\salt=".*?"><br>(.*?)<br>/x)
	{
		$descr = $1;
	}
	
	return $descr;
}

