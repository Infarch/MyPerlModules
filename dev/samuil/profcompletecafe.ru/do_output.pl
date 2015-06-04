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
use ISoft::DB;



#use ISoft::ParseEngine::ThreadProcessor;
use Category;
use Product;

our $no_copy = 1;

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


# products_pictures

our $pic_storage = 'output_files/products_pictures';
unless (-e $pic_storage && -d $pic_storage){
	mkpath($pic_storage);
}

our $prices = 'output_prices';



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
		{name=>'Мебель для Баров Кафе Ресторанов', page_id=>'Мебель для Баров Кафе Ресторанов', suppress_defaults=>1}
	);
	foreach my $topitem (@toplist){
		my $cid = $topitem->ID;
		if ($cid == 87){
			$root = $topitem;
			next;
		}
		process_category($dbh, $topitem, \@collector, '!');
		print "Category $cid  processed\n";
	}

	push @collector,
		{name=>$root->get('Name'), page_id=>$root->get('Name'), suppress_defaults=>1};
	
	@toplist = $root->getCategories($dbh);
	foreach my $topitem (@toplist){
		my $cid = $topitem->ID;
		process_category($dbh, $topitem, \@collector, '!');
		print "Category $cid  processed\n";
	}
	
	save_csv("export_full.csv", \@collector);
	
	$dbh->rollback();
}

sub process_data_multifiles {
	
	die "Blocked!";
	
	my $dbh = get_dbh();
	
	# get root directory
	my $root = Category->new;
	$root->set('Category_ID', undef);
	$root->select($dbh);
	
	my @toplist = $root->getCategories($dbh);
	
	my $counter = 1;
	foreach my $topitem (@toplist){
		my @collector = (
			{name=>'profcompletecafe', suppress_defaults=>1}
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
	
	get_prices($dbh, $category, $category->ID, undef);
	
	my %h = (
		name => $spacer.$category->Name,
		page_id => $category->Name,
		suppress_defaults => 1
	);
	
	# look for picture
	if ( defined(my $pic_obj = $category->getPicture($dbh)) ){
		my $path = 'output_files/cats_products';
		my $name = sprintf('pccf_cat_%05d.jpg', $pic_obj->ID);
		my $path_name = "$path/$name";
		if(-e $path_name){
			copy($path_name, "$pic_storage/$name") unless $no_copy;
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

sub get_prices {
	my ($dbh, $owner_obj, $category_id, $product_id) = @_;
	
	return 0;
	
	my $member_obj = Price->new;
	
	if($category_id){
		$member_obj->set('Category_ID', $category_id);
	} elsif ($product_id){
		$member_obj->set('Product_ID', $product_id);
	} else {
		die 'wtf';
	}
	
	my @list = $member_obj->listSelect($dbh);
	if(@list>0){
		print scalar @list, " price(s)\n";

		my $url = $owner_obj->get('URL');
		
		$url =~ s/^http:\/\/www\.profcomplete(cafe|hotel)\.ru\/catalog\///;
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
	
	get_prices($dbh, $product, undef, $product->ID);
	
	my $descr = process_description($dbh, $product);
	my $delivery;
	if ($descr=~/<div><b>(Срок доставки: )<\/b><span>(.+?)<\/span>/){
		$delivery = $2;
	} elsif ($descr=~/<div><b>(Наличие: )<\/b><span>(.+?)<\/span>/){
		$delivery = $2;
	}	elsif ($descr=~/<td class="l_c">(Срок изготовления:)<\/td><td class="r_c">(.+?)<\/td>/){
		$delivery = $2;
	} else {
		$delivery = 5-10;
	}
	
	$delivery =~ s/20-30/10-15/;
	$delivery =~ s/10-20/5-10/;
	$delivery =~ s/1-5/1-3/;

	$delivery = "Наличие: $delivery";

	$descr =~ s/20-30/10-15/;
	$descr =~ s/10-20/5-10/;
	$descr =~ s/1-5/1-3/;
	
	my $code = sprintf('pccf%05d', $product->ID);
	my $price = $product->get('Price');
	my $pricetext = "Цена комплекта:";
	if(!$price && $descr=~/<!--minprice:(\d+)-->/){
		$price = $1;
		$pricetext = "Цена от:";
	}
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
		my $path = 'output_files/cats_products';
		my $info_name = sprintf('pccf_info_%05d.jpg', $pid);
		if (-e "$path/$info_name"){
			
			# let us assume that other images exist too :)
			my $th_name = sprintf('pccf_th_%05d.jpg', $pid);
			my $org_name = sprintf('pccf_org_%05d.jpg', $pid);
			
			unless($no_copy){
				copy("$path/$info_name", "$pic_storage/$info_name") or die 'fuck again!';
				copy("$path/$th_name", "$pic_storage/$th_name") or die 'fuck again!';
				copy("$path/$org_name", "$pic_storage/$org_name") or die 'fuck again!';
			}
			
			push @list, $info_name;
			push @list, $th_name;
			push @list, $org_name;
		} else {
			print "No product picture $pid\n";
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
			my $pdp_obj = $obj->newProductDescriptionPicture();
			$pdp_obj->set('ID', $id);
			$pdp_obj->select($dbh);
			
			my $org = $pdp_obj->getMD5Name();
			my $src = "/published/publicdata/MEBELI84SHCM/attachments/SC/supplementary_pictures/pccf/$org";
			$image->attr('src', $src);
			
		} else {
			print "Image without the source\n"
		}
		
		$image->attr('isoft:id', undef);
	}
		
	# select onchange
	my @selects = $tree->findnodes( q{//select} );
	foreach my $select (@selects){
		$select->delete();
	}
	
	# re-ordering of the description parts
	
	# get nodes
	my @nodelist = $tree->findnodes( q{/html/body/*} );
	
	my $minprice;
	
	my @tables1;
	my @tables2;
	
	my $s3_item;
	my @s3_list;
	
	
	
	my $cc = '';
	
	foreach my $descr_node (@nodelist){
		
		my $sn = $descr_node->attr('section', undef);
		
		if ($descr_node->attr('id') && ($descr_node->attr('id') eq 'category_content_1' || $descr_node->attr('id') eq 'category_content_3')){
			$cc .= $descr_node->as_HTML('<>&', '', {});
			next;
		}

		my $temp_html;
		
		if($sn==3){
			
			if($descr_node->attr('class') eq 'item_category_title'){
				$s3_item = {
					title => $descr_node->findvalue( q{./a} ),
					list => []
				};
				push @s3_list, $s3_item;
			} else {
				unless (defined $s3_item){
					$s3_item = {
						list => []
					};
					push @s3_list, $s3_item;
				}
				my @legend_rows = $descr_node->findnodes( q{.//table[@class='legend_table']/tr} );
				foreach my $lr (@legend_rows){
					if( $lr->findvalue( q{./td[2]/span} ) ){
						# looks as Price row, remove
						$lr->delete();
						last;
					}
				}
				# extract html, add to container
				#$descr_node->attr('style', 'margin: 0 20px 20px 0');
				push @{$s3_item->{list}}, $descr_node->as_HTML('<>&', '', {});
			}
			
		} elsif($descr_node->attr('id') && $descr_node->attr('id') eq 'bottom_colors'){
			my @colornodes = $descr_node->findnodes( q{.//div[@class='float_colors']} );
			my $cols = 2;
			my $rows = int( (@colornodes+$cols-1)/$cols );
			
			$temp_html = "<table width='100%'>";
			for (my $i=0; $i<$rows; $i++){
				$temp_html .= "<tr>";
				if($i==0){
					$temp_html .= "<td rowspan='$rows' width='75'><b>Цвета:</b></td>";
				}
				for(my $k=0; $k<$cols; $k++){
					my $cn = shift @colornodes;
					my $cnt = '';
					if(defined $cn){
						$cn->attr('style', 'margin: 5px;');
						$cnt = $cn->as_HTML('<>&', '', {});
					}
					$temp_html .= "<td>$cnt</td>";
				}
				$temp_html .= "</tr>";
			}
			$temp_html .= "</table>";
			
		} else {
			
			my @pdlist = $descr_node->findnodes( q{.//div[@class='p_d']} );
			
			foreach my $pdi (@pdlist){
				#$pdi->attr('style', 'float: left; margin-right: 10px;');
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
				$pdi->delete();
			}
			
			$descr_node->attr('width', '100%') if $sn==2;
			
			$temp_html = $descr_node->as_HTML('<>&', '', {});	
		}
		
		if($sn==1){
			push @tables1, $temp_html;
		} elsif ($sn==2){
			push @tables2, $temp_html;
		}
		
	}
	
	# all nodes were processed, make output html
	
	if($cc){
		unshift @tables1, $cc;
	}
	
	$content = '';
	if(@tables1 > 0){
		$content = '<table><tr><td>';
		$content .= join '<br/>', @tables1;
		$content .= '</td></tr></table>';
	}
	
	if(@tables2 > 0){
		$content .= '<br/>';
		$content .= join '<br/>', @tables2;
	}

	# groups
	my $is_first_group = 1;
	if(@s3_list > 0){
		$content .= "<br/><table>";
		my $columns = 4;
		
		foreach my $tmp_group (@s3_list){
			my $title = $tmp_group->{title};
			$content .= "<tr height='20'><td colspan='$columns'></td></tr>" unless $is_first_group;
			$is_first_group = 0;
			$content .= "<tr><td colspan='$columns' style='font-size:21px'>$title</td></tr>" if $title;

			my @groupitems = @{ $tmp_group->{list} };
			
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
		
	
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	
	#$content =~ s/Стоимость базового комплекта/Стоимость комплекта/g;

	# no price!
	$content =~ s/<div><b>[^<]+<\/b>\s*<span class="span_price"[^>]*>[\s\d]* руб\.<\/span><\/div>//;

	# mask the brand
	$content =~ s/<tr class="second"><td class="l_c">Бренд:<\/td><td class="r_c">(.*?)<\/td><\/tr>/<tr class="second" style="color:#fff"><td class="l_c">Бренд:<\/td><td class="r_c">$1<\/td><\/tr>/;



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

sub save_csv {
	my ($name, $data_ref) = @_;
	my $result_ref = webassyst_provider($data_ref);
	
#	open (CSVU, '>:encoding(utf-8)', 'export_profcompletecafe_utf.csv')
#		or die "Cannot open file: $!";

	open (CSVC, '>', 'export_profcompletecafe_cp1251.csv')
		or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
#		print CSVU $line, "\n";
		$line = encode('cp1251', $line, Encode::FB_DEFAULT);
		print CSVC $line, "\n";
	}
	
#	close CSVU;
	close CSVC;
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql(
		$constants{Database}{DB_Name},
		$constants{Database}{DB_User},
		$constants{Database}{DB_Password},
		$constants{Database}{DB_Host}
	);
}
