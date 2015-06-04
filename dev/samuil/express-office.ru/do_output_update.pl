use strict;
use warnings;

use utf8;

use Data::Dumper;
use Encode qw/encode decode/;
use Error ':try';
use File::Path;
use File::Copy;
use HTML::TreeBuilder::XPath;
use Image::Resize;



use lib ("/work/perl_lib");
use ISoft::ParseEngine::ThreadProcessor;
use Category;
use Product;
use ProductDescriptionPicture;


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


our $products_pictures = 'output_pictures/products_pictures';
our $supplementary_pictures = 'output_pictures/supplementary_pictures/expr';
our $prices = 'output_prices';

our $pp_win = $products_pictures;
$pp_win =~ s#/#\\\\#g;



# init
if(!-e $products_pictures || !-d $products_pictures){
	mkpath($products_pictures );
}
if(!-e $supplementary_pictures || !-d $supplementary_pictures){
	mkpath($supplementary_pictures );
}




process_data_singlefile();

exit;

# -----------------------------------------------------------------------------------------

sub process_data_singlefile {
	
	# get database handler
	my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
	my $dbh = $tp->getDbh();
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	
	my @toplist = $root->getCategories($dbh);

	my @collector = (
		{name=>'Express updates', suppress_defaults=>1}
	);
	
	foreach my $topitem (@toplist){
		process_category($dbh, $topitem, \@collector, '!');
		print "Top category processed\n";
	}
	
	save_csv("export_updates.csv", \@collector);
	
	$dbh->rollback();
}

sub save_csv {
	my ($name, $data_ref) = @_;
	my $result_ref = webassyst_provider($data_ref);
	my $c=0;
	open (CSV, '>:encoding(utf-8)', $name)
		or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
		print CSV $line, "\n";
		$c++;
	}
	close CSV;
	print "saved $c lines\n";
}

sub get_prices {
	my ($dbh, $product_obj) = @_;
	
	my $member_obj = Price->new;
	$member_obj->set('Product_ID', $product_obj->ID);
	
	my @list = $member_obj->listSelect($dbh);
	if(@list>0){
		print scalar @list, " price(s)\n";

		my $url = $product_obj->get('URL');
		$url =~ s/^http:\/\/www\.express-office\.ru\/catalog\///;
		$url =~ s/\/([^\/]+|)$//;

		my $pricepath = "$prices/$url";
		if(!-e $pricepath || !-d $pricepath){
			mkpath($pricepath);
		}

		foreach my $price (@list){
			my $pname = $price->getStoragePath();
			copy($pname, $pricepath.'/'.$price->ID.'.pdf');
		}
	}
	
}

sub do_convert {
	
	unless (system("c:\\work\\im\\convert.exe", @_)==0){
		die "Error!";
	}
	
}

sub process_product {
	my($dbh, $product, $collector) = @_;
	
	get_prices($dbh, $product);
	
	my $descr = process_description($dbh, $product);
	my $delivery;
	if ($descr=~/<div><b>(Срок доставки: )<\/b><span>(.+?)<\/span>/){
		$delivery = $2;
	} elsif ($descr=~/<div><b>(Наличие: )<\/b><span>(.+?)<\/span>/){
		$delivery = $2;
	}	elsif ($descr=~/<td class="l_c">(Срок изготовления:)<\/td><td class="r_c">(.+?)<\/td>/){
		$delivery = $2;
	} else {
		$delivery = '5-10';
	}

	$delivery =~ s/20-30/10-15/;
	$delivery =~ s/10-20/5-10/;
	$delivery =~ s/1-5/1-3/;

	$delivery = "Наличие: $delivery";

	$descr =~ s/20-30/10-15/;
	$descr =~ s/10-20/5-10/;
	$descr =~ s/1-5/1-3/;


	my $code = sprintf('ex%05d',  $product->ID);
	my $price = $product->get('Price');
	my $pricetext = "Цена комплекта:";
	if(!$price && $descr=~/<!--minprice:(\d+)-->/){
		$price = $1;
		$pricetext = "Цена от:";
	}
	my %h = (
		code => $code,
		name => $product->Name,
		price => $price,
		description => $descr,
		brief_description => "<nobr>$delivery</nobr><br/>$pricetext"
	);
	
	
	my @pics = $product->getPictures($dbh);
	my $count = 1;
	foreach my $pic_obj (@pics){
		
		my $pid = $pic_obj->ID;
		my @list;
		
		my $stored = $pic_obj->getStoragePath();
		
		
		if(-e $stored){
			
			$stored =~ s#/#\\\\#g;
			
			# info
			my $info_name = sprintf('expr_info_%05d.jpg', $pid);
			do_convert($stored, "-resize", '"300x400>"', "$pp_win\\$info_name");
			push @list, $info_name;
			
			# thumbnail
			my $th_name = sprintf('expr_th_%05d.jpg', $pid);
			do_convert($stored, "-resize", '"150x200>"', "$pp_win\\$th_name");
			push @list, $th_name;

			# org - just convert
			my $org_name = sprintf('expr_org_%05d.jpg', $pid);
			do_convert($stored, "$pp_win\\$org_name");
			push @list, $org_name;
			
		} else {
			print "No product picture $pid\n$stored\n";
			next;
		}
		
		my $str = join ',', @list;
		$h{"picture_$count"} = $str;
		
		$count++;
	}
	
	push @$collector, \%h;
	
}

sub process_products {
	my ($dbh, $category, $collector, $allow_prod_ids) = @_;
	
	my @prodlist = $category->getNewProducts($dbh, $allow_prod_ids);
	foreach my $product (@prodlist){
		process_product($dbh, $product, $collector);
	}
	
}

sub process_category {
	my ($dbh, $category, $collector, $spacer, $allow_cat_ids, $allow_prod_ids) = @_;
	
	my %h = (
		name => $spacer.$category->Name,
		suppress_defaults => 1
	);
	
#	# look for picture
#	if ( defined(my $pic_obj = $category->getPicture($dbh)) ){
#		my $name = sprintf('expr_cat_%05d.jpg', $pic_obj->ID);
#		if(-e "files/pp_done/$name"){
#			$h{picture_1} = $name;
#		} else {
#			print "No category picture $name\n";
#		}
#	}

	push @$collector, \%h;
	
	process_products($dbh, $category, $collector, $allow_prod_ids);

	my @sublist = $category->getCategories($dbh, $allow_cat_ids);
	foreach my $item (@sublist){
		process_category($dbh, $item, $collector, $spacer.'!', $allow_cat_ids, $allow_prod_ids);
	}
	
}

sub process_description {
	my ($dbh, $obj) = @_;
	
	my $description = $obj->get("Description");
	
	# a hack
	if ($description =~ /class="cat4"/){
		$description =~ s/^<td colspan="2">(.*?)<\/td>$/<span class="hack">$1<\/span>/m;
	}
	
	my $content = "<html><body>$description</body></html>";
	

	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	
	# the latest correction - javascript links
	my @alist = $tree->findnodes(q{//a[@href]});
	foreach my $a (@alist){
		my $href = $a->attr('href');
		if( $href =~ /javascript/i ){
			my $parent = $a->parent();
			my @x = $a->detach_content();
			$a->postinsert(@x);
			$a->delete();
		}
	}
	
	# images
	my @images = $tree->findnodes( q{//img} );
	foreach my $image (@images){
		if($image->attr('src')){
			my $id = $image->attr('isoft:id');
			my $obj = ProductDescriptionPicture->new;
			$obj->set('ID', $id);
			$obj->select($dbh);
			
			my $org = $obj->getMD5Name();
			my $src = "/published/publicdata/MEBELI84SHCM/attachments/SC/supplementary_pictures/expr/$org";
			$image->attr('src', $src);
			
			# do copy
			copy($obj->getStoragePath(), "$supplementary_pictures/$org");
			
		} else {
			print "Image without the source\n"
		}
		
		$image->attr('isoft:id', undef);
	}
		
	# select onchange
	my @selects = $tree->findnodes( q{//select} );
	foreach my $select (@selects){
		$select->attr('onchange', undef);
		$select->attr('name', undef);
	}
	
	# re-ordering of the description parts
	
	# get nodes
	my @nodelist = $tree->findnodes( q{/html/body/*} );
	
	# parse nodes
	my @groups;
	my $group;
	my $d1;
	my $d3;
	my $bt;
	my $tc;
	my $c4 = '';
	my $c4h;
	my $minprice;
	foreach my $descr_node (@nodelist){
		
		if($descr_node->attr('id') && $descr_node->attr('id') eq 'bottom_colors'){
			
			my @colornodes = $descr_node->findnodes( q{.//div[@class='float_colors']} );
			my $cols = 2;
			
			my $rows = int( (@colornodes+$cols-1)/$cols );
			
			$tc = "<table width='100%'>";
			for (my $i=0; $i<$rows; $i++){
				$tc .= "<tr>";
				if($i==0){
					$tc .= "<td rowspan='$rows' width='75'><b>Цвета:</b></td>";
				}
				
				for(my $k=0; $k<$cols; $k++){
					my $cn = shift @colornodes;
					my $cnt = '';
					if(defined $cn){
						$cn->attr('style', 'margin: 5px;');
						$cnt = $cn->as_HTML('<>&', '', {});
					}
					$tc .= "<td>$cnt</td>";
				}
				
				$tc .= "</tr>";
			}
			
			$tc .= "</table>";
						
		} elsif ($descr_node->attr('id') && $descr_node->attr('id') eq 'category_content_1'){
			# main description
			$d1 = $descr_node;
		} elsif ($descr_node->attr('id') && $descr_node->attr('id') eq 'category_content_3'){
			# additional description
			$d3 = $descr_node;
		} elsif ($descr_node->attr('class') && $descr_node->attr('class') eq 'item_category_title'){
			if (defined $group){
				# push the old group
				push @groups, $group;
			}
			# create a new group
			$group = {
				title => $descr_node->as_text(),
				items => []
			};
		} elsif ($descr_node->attr('class') && $descr_node->attr('class') eq 'element_item'){
			# remove price from the element
			my @legend_rows = $descr_node->findnodes( q{.//table[@class='legend_table']/tr} );
			foreach my $lr (@legend_rows){
				if( $lr->findvalue( q{./td[2]/span} ) ){
					# looks as Price row, remove
					$lr->delete();
					last;
				}
			}
			# extract html, add to container
			push @{$group->{items}}, $descr_node->as_HTML('<>&', '', {});
		} elsif ($descr_node->attr('class') && $descr_node->attr('class') eq 'behaviour'){
			$bt = $descr_node;
		} elsif ($descr_node->attr('class') && $descr_node->attr('class') eq 'cat4'){
			
			my @pdlist = $descr_node->findnodes( q{.//div[@class='p_d']} );
			foreach my $pdi (@pdlist){
				$pdi->attr('style', 'float: left; margin-right: 10px;');
				# look for price
				my @pricenodes = $pdi->findnodes( q{.//font} );
				foreach my $pricenode (@pricenodes){
					my $val = $pricenode->as_text();
					$val =~ s/\D//g;
					if($val=~/\d/){
						if (defined $minprice){
							$minprice = $val if $val < $minprice
						} else {
							$minprice = $val;
						}
					}
				}
			}
			
			$c4 .= $descr_node->as_HTML('<>&', '', {});
			$c4 .= "<br/><br/>";
			
		} elsif ($descr_node->attr('class') && $descr_node->attr('class') eq 'hack'){
			
			$c4h = "<br/>" . $descr_node->as_HTML('<>&', '', {}) . "<br/>";
			
		} else {
			
			print "Unrecognized node in ", $obj->ID, "\n";
			
			$c4 = $descr_node->as_HTML('<>&', '', {}) . $c4;
		}
		
	}
	if (defined $group){
		# push the last group
		push @groups, $group;
	}
	
	# all nodes were processed, make output html
	
	$content = '<table><tr><td>';
	
	$content .= $d1->as_HTML('<>&', '', {}) if defined $d1;
	$content .= $d3->as_HTML('<>&', '', {}) if defined $d3;
	$content .= $bt->as_HTML('<>&', '', {}) if defined $bt;
	$content .= $c4h if $c4h;
	
	# color table
	if ($tc){
		$content.="<br/>$tc";
	}
	
		# close content table
	$content .= '</td></tr></table>';


	# c4
	$content .= "<table width='100%'><tr><td>$c4</td></tr></table>" if $c4;
	
	# groups
	if(@groups > 0){
		$content .= "<br/><table>";
		my $columns = 4;
		
		foreach my $tmp_group (@groups){
			my $title = $tmp_group->{title};
			$content .= "<tr height='20'><td colspan='$columns'></td></tr><tr><tr><td colspan='$columns'>$title</td></tr><tr>";

			my @groupitems = @{ $tmp_group->{items} };
			
			my $rows = int( (@groupitems+$columns-1) / $columns );
			
			while($rows--){
				$content .= "<tr>";
				for (my $i=0; $i<$columns; $i++){
					my $td = (shift @groupitems) || '';
					$content .= "<td>$td</td>";
				}
				$content .= "</tr>";
			}
		}
		
		$content .= "</table>";
	}
		
	$content =~ s/Стоимость базового комплекта/Стоимость комплекта/g;
	
	$content =~ s/\r|\n|\t/ /g;
	
	if (defined $minprice){
		$content .= "<!--minprice:$minprice-->";
	}
	# release the tree
	$tree->delete();
	
	return $content;
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
