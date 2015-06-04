use strict;
use warnings;

use utf8;

use Data::Dumper;
use Encode qw/encode decode/;
use Error ':try';
use File::Path;
use File::Copy;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;



use Category;
use Product;
use ProductPicture;
use AssemblyManual;



# setup dumper
$Data::Dumper::Indent = 1;
$Data::Dumper::Pair = ':';
# a hack allowing to dump data in utf8
$Data::Dumper::Useqq = 1;
{
	no warnings 'redefine';
	sub Data::Dumper::qquote {
		my $s = shift;
		return "'$s'";
	}
}



our $prefix = 'qps';

our $cat_pic_mask = $prefix . '_cat_%05d.jpg';

our $article_mask = $prefix . '%05d';

our $prod_pic_info_mask = $prefix . '_info_%05d.jpg';
our $prod_pic_th_mask = $prefix . '_th_%05d.jpg';
our $prod_pic_org_mask = $prefix . '_org_%05d.jpg';




# products_pictures

our $pic_src = 'files/output/cats_products';
our $pic_dest = 'files/output/products_pictures';

unless (-e $pic_dest && -d $pic_dest){
	mkpath($pic_dest);
}


#process_data_multifiles();
process_data_singlefile();


exit;

# -----------------------------------------------------------------------------------------

sub process_data_singlefile {
	
	my $dbh = get_dbh();
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	
	my @toplist = $root->getCategories($dbh);

	my @collector = (
		{name=>'Мебель для дома', page_id=>'Мебель для дома', suppress_defaults=>1}
	);
	
	foreach my $topitem (@toplist){
		process_category($dbh, $topitem, \@collector, '!');
		print "Top category processed\n";
	}
	
	save_csv("export_full.csv", \@collector);
	
	$dbh->rollback();
}

sub process_data_multifiles {
	
	my $dbh = get_dbh();
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	
	my @toplist = $root->getCategories($dbh);

	my $counter = 1;
	foreach my $topitem (@toplist){
		my @collector = (
			{name=>'qpstol', suppress_defaults=>1}
		);
		process_category($dbh, $topitem, \@collector, '!');
		save_csv("export_$counter.csv", \@collector);
		$counter++;
		print "Top category processed\n";
	}
	
	$dbh->rollback();
}

sub process_category {
	my ($dbh, $category, $collector, $spacer) = @_;
	my $name = $spacer.$category->Name;
	
	$name =~ s/\r|\n|\t//g;
	
	my %h = (
		name => $name,
		page_id => $category->Name,
		suppress_defaults => 1
	);
	
	# look for picture
	if ( defined(my $pic_obj = $category->getPicture($dbh)) ){
		my $name = sprintf($cat_pic_mask, $pic_obj->ID);
		my $path_name = "$pic_src/$name";
		if(-e $path_name){
			copy($path_name, "$pic_dest/$name") or die 'fuck!';
			$h{picture_1} = $name;
		}
	}

	push @$collector, \%h;
	
	process_products($dbh, $category, $collector);

	my @sublist = $category->getCategories($dbh);
	foreach my $item (@sublist){
		process_category($dbh, $item, $collector, $spacer.'!');
	}
	
}

sub process_products {
	my ($dbh, $category, $collector) = @_;
	
	my @prodlist = $category->getProducts($dbh);
	foreach my $product (@prodlist){
		next if $product->isFailed();
		process_product($dbh, $product, $collector);
	}
	
}

sub process_product {
	my($dbh, $product, $collector) = @_;
	
	my $descr = process_description($dbh, $product);
	
	my $delivery = "Наличие: 1-5 дней";

	my $code = sprintf($article_mask, $product->ID);
	
	my $price = $product->get('Price');
	my $pricetext = "Цена:";

	my %h = (
		code => $code,
		name => $product->Name,
		page_id => $product->Name,
		price => $price,
		description => $descr,
		brief_description => "<nobr>$delivery</nobr><br/>$pricetext"
	);
	
	my @pics = $product->getProductPictures($dbh);
	my $count = 1;
	foreach my $pic_obj (@pics){
		
		my $pid = $pic_obj->ID;
		my @list;
		
		# info
		my $info_name = sprintf($prod_pic_info_mask, $pid);
		if (-e "$pic_src/$info_name"){
			
			# let us assume that other images exist too :)
			my $th_name = sprintf($prod_pic_th_mask, $pid);
			my $org_name = sprintf($prod_pic_org_mask, $pid);
			
			copy("$pic_src/$info_name", "$pic_dest/$info_name") or die 'fuck again!';
			copy("$pic_src/$th_name", "$pic_dest/$th_name") or die 'fuck again!';
			copy("$pic_src/$org_name", "$pic_dest/$org_name") or die 'fuck again!';
			
			push @list, $info_name;
			push @list, $th_name;
			push @list, $org_name;
		}
		
		my $str = join ',', @list;
		$h{"picture_$count"} = $str;
		
		$count++;
	}
	
	push @$collector, \%h;
	
}

sub process_description {
	my ($dbh, $obj) = @_;
	
	my $description = $obj->get("Description");
	
	my $content = "<html><body>$description</body></html>";

	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
		
	# images
	my @images = $tree->findnodes( q{//img} );
	foreach my $image (@images){
		my $id = $image->attr('isoft:id', undef);
		if($image->attr('src')){
			
			my $pdp_obj = $obj->newProductDescriptionPicture();
			$pdp_obj->set('ID', $id);
			$pdp_obj->select($dbh);
			
			my $org = $pdp_obj->getMD5Name();
			my $src = "/published/publicdata/MEBELI84SHCM/attachments/SC/supplementary_pictures/$prefix/$org";
			$image->attr('src', $src);
			
		}
	}

	# <a>
	my @alist = $tree->findnodes( q{//a} );
	my $href;
	foreach my $a (@alist){
		my $id = $a->attr('isoft:id', undef);
		if($id){
			my $am = new AssemblyManual;
			$am->set('ID', $id);
			$am->select($dbh);
			my $org = $am->getMD5Name();
			$href = "/published/publicdata/MEBELI84SHCM/attachments/SC/supplementary_pictures/$prefix/$org";
			$a->attr('href', $href);
		} else {
			if($href){
				# the link is the same as the previous one
				$a->attr('href', $href);
				$href = '';
			} else {
				# remove the <a>, move all nested nodes up
				dissolve($a);
			}
		}
	}
	
	# parse description nodes
	
	# get nodes
	my @nodelist = $tree->findnodes( q{/html/body/div/*} );
	
	my @colors;
	my $block = 0;
	
	$content = '';
	
	foreach my $node (@nodelist){
		
		my $html;
		
		my $tag = $node->tag();
		if ($tag eq 'h2'){
			my $htext = $node->as_text();
			$block = $htext =~ /^Стоимость сборки/;
		} elsif ($tag eq 'form'){
			$block = 0;
			# extract colors, make table
			extract_colors($dbh, $node, \@colors);
			$html = make_color_table(\@colors);
		} elsif ($tag eq 'div'){
			
			my $class = $node->attr('class');
			if($class && $class eq 'radius_grey'){
				$block = 0;
				next;
			}
			
			my $style = $node->attr('style');
			if ($style && $style eq 'position:relative;'){
				$html = '<table><tr><td>' . $node->as_HTML('<>&', '', {}) . '</td></tr></table>';
			}
		}
		
		next if $block;
		
		$html = $node->as_HTML('<>&', '', {}) unless $html;
		
		$content .= $html;
	}
	
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	
	# release the tree
	$tree->delete();
	
	return $content;
}

sub extract_colors {
	my ($dbh, $source, $listref) = @_;
	
	my @nodes = $source->findnodes( q{.//img | .//div[@class='txt']} );
	
	my $storage = {name=>'',img=>''};
	
	foreach my $node (@nodes){
		
		my $tagname = $node->tag();
		
		if($tagname eq 'img'){
			
			push @$listref, $storage;
			$storage->{img} = $node->attr('src');
			
		} else {
			
			$storage->{name} = $node->as_text();
			$storage = {name=>'',img=>''};
		}
		
	}
	
}
	
sub make_color_table {
	my ($listref) = @_;
	
	my $columns = 3;
	
	my $content = '<h2>Доступные цвета</h2><table cellspacing=\'10\'>';
	
	my @items = @$listref;
	
	my $rows = int( (@items+$columns-1) / $columns );
	
	while($rows--){
		$content .= "<tr>";
		for (my $i=0; $i<$columns; $i++){
			my $data = shift @items;
			my $td = '';
			if(defined $data){
				my $img = "<img src='$data->{img}' />";
				$td = "$img<br/>$data->{name}";
			}
			$content .= "<td>$td</td>";
		}
		$content .= "</tr>";
	}
	$content .= "</table>";
	
	return $content;
}

sub dissolve {
	my ($node) = @_;
	my @x = $node->detach_content();
	$node->postinsert(@x);
	$node->delete();
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
		
		{ title=>'Покрытие (Русский)', mapto=>'cover' },
		{ title=>'Покрытие (English)', mapto=>'cover_en' },
		
		{ title=>'Цвет (Русский)', mapto=>'color'},
		{ title=>'Цвет (English)', mapto=>'color_en'},
		
		{ title=>'Производитель (Русский)', mapto=>'vendor'},
		{ title=>'Производитель (English)', mapto=>'vendor_en'},
		
		{ title=>'Срок доставки (Русский)', mapto=>'ship_term'},
		{ title=>'Срок доставки (English)', mapto=>'ship_term_en'},
		
		
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
	my ($name, $data_ref) = @_;
	my $result_ref = webassyst_provider($data_ref);
	
	open (CSVU, '>:encoding(utf-8)', 'export_qpstol_utf.csv')
		or die "Cannot open file: $!";

	open (CSVC, '>', 'export_qpstol_cp1251.csv')
		or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
		print CSVU $line, "\n";
		$line = encode('cp1251', $line, Encode::FB_DEFAULT);
		print CSVC $line, "\n";
	}
	
	close CSVU;
	close CSVC;
}

