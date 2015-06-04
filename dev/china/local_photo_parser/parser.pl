use strict;
use warnings;

use utf8;

use Encode 'encode';
use PDF::Report;

use SimpleConfig;

# prepare environment
if(!-e $constants{General}{OutputDirectory}){
	mkdir $constants{General}{OutputDirectory} or die $!;
}
our $files_path = $constants{General}{OutputDirectory}.'/products_pictures';
if(!-e $files_path){
	mkdir $files_path or die $!;
}
my @list = glob $files_path.'/*.*';
unlink @list;


# process products
my ($products, $reports) = extract_products($constants{General}{ScanDirectory});

# make csv
save_csv("$constants{General}{OutputDirectory}/export.csv", $products);

save_report($reports);

exit;

sub save_report {
	my ($reports) = @_;
	
	my $pdf = new PDF::Report(PageSize=>'A4', PageOrientation=>'Portrait');
	$pdf->newpage();
	
	my $tm = localtime time;
	
	$pdf->addText("Local parser report (created $tm)\n\n");
	$pdf->addText("$constants{General}{ScanDirectory}\n\n");
	$pdf->addText("-------------------------------------------------------------\n\n");
	
	my $z = 2;
	
	foreach my $report (@$reports){
		
		add_block($pdf, $report->{article}, $report->{thumbnails});
		
		unless($z++ % 5){
			$pdf->newpage();
			$pdf->setAddTextPos(30, 788);
		}

	}
	
	$pdf->saveAs("$constants{General}{OutputDirectory}/report.pdf");
	
}

sub add_block {
	my ($pdf, $title, $images) = @_;
	$pdf->addText("$title\n");
	
	my ($hPos, $vPos) = $pdf->getAddTextPos();
	
	my $cnt = 0;
	foreach my $image (@$images){
		$pdf->addImgScaled($image, $hPos + ($cnt++ * 120), $vPos-115, 0.75);
		last if $cnt==4;
	}
	
	# update the vertical position
	$pdf->setAddTextPos($hPos, $vPos-150);
	
}

sub extract_products {
	my $dir = shift;
	
	my @collector;
	
	my $products = get_files($dir);
	
	my $acode = $constants{General}{Code};
	my $anumber = $constants{General}{StartFrom};
	
	my @reports;
	
	foreach my $product (@$products){
		my @photos;
		print "Processing $product\n";
		if (!-d "$dir/$product"){
			push @photos, "$dir/$product";
		} else {
			my $subdir = "$dir/$product";
			my $sublist = get_files($subdir);
			foreach my $subitem(@$sublist){
				push @photos, "$subdir/$subitem";
			}
		}
		
		my @thumbnails;
		
		push @collector, make_product("$acode$anumber", $product, \@photos, \@thumbnails);
		
		push @reports, {
			thumbnails=>\@thumbnails,
			article=>"$acode$anumber"
		};
		
		$anumber++;
	}
	return (\@collector, \@reports);
}

sub make_product {
	my ($article, $price, $photos, $thumbnails) = @_;

	$price =~ s/\..*//;
	
	my $pdata = {
		code => $article,
		price => $price
	};
	
	my $la = lc $article;
	
	my $count = 1;
	foreach my $photo (@$photos){

		my @list;
		
		# info
		my $info_name = "${count}_$la.jpg";
		convert_picture($photo, "-resize", '"300>"', "$files_path\\$info_name");
		push @list, $info_name;
		
		# thumbnail
		my $th_name = "${count}_${la}_th.jpg";
		convert_picture($photo, "-resize", '"200x150>"', "$files_path\\$th_name");
		push @list, $th_name;

		push @$thumbnails, "$files_path/$th_name";
		
		# org - just convert
		my $org_name = "${count}_${la}_enl.jpg";
		convert_picture($photo, "$files_path\\$org_name");
		push @list, $org_name;
			
		my $str = join ',', @list;
		$pdata->{"picture_$count"} = $str;
		
		$count++;
	}
	return $pdata;
}

sub get_files {
	my $dir = shift;
	opendir DIR, $dir or die "Could not open $dir: $!";
	my @files = grep { !/\.db$/i } grep { /^[^.]/ } readdir DIR;
	closedir DIR;
	return \@files;
}


sub save_csv {
	my ($name, $data_ref) = @_;
	my $result_ref = webassyst_provider($data_ref);
	my $c=0;
	open (CSV, '>', $name) or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
		$line = encode('cp1251', $line, Encode::FB_DEFAULT);
		$line =~ s/\?//g;
		print CSV $line, "\n";
		$c++;
	}
	
	close CSV;
	print "saved $c lines\n";
}

sub webassyst_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'Артикул', mapto=>'code', force_quote=>1 },
		{ title=>'Наименование', mapto=>'name' },
		
		{ title=>'Основная категория', mapto=>'none' },
		{ title=>'Дополнительные категории', mapto=>'none' },
		{ title=>'Цена поставщика', mapto=>'none' },
		
		{ title=>'"ID страницы (часть URL; используется в ссылках на эту страницу)"', mapto=>'page_id' },
		{ title=>'Цена', mapto=>'price', default=>'0.01' },
		{ title=>'Название вида налогов', mapto=>'none' },
		{ title=>'Скрытый', mapto=>'none' },
		{ title=>'Можно купить', mapto=>'none', default=>1 },
		{ title=>'Старая цена', mapto=>'none', default=>0 },
		{ title=>'Продано', mapto=>'none', default=>0 },
		{ title=>'Описание', mapto=>'description', quote=>1 },
		{ title=>'Краткое описание', mapto=>'none' },
		{ title=>'Сортировка', mapto=>'none', default=>0 },
		{ title=>'Заголовок страницы', mapto=>'none' },
		{ title=>'Тэг META keywords', mapto=>'none' },
		{ title=>'Тэг META description', mapto=>'none' },
		{ title=>'Стоимость упаковки', mapto=>'none', default=>0 },
		{ title=>'Вес продукта', mapto=>'none', default=>0 },
		{ title=>'Бесплатная доставка', mapto=>'none', default=>0 },
		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'none', default=>1 },
		{ title=>'Файл продукта', mapto=>'none' },
		{ title=>'Количество дней для скачивания', mapto=>'none', default=>5 },
		{ title=>'Количество загрузок (раз)', mapto=>'none', default=>5 },
		{ title=>'Фотография', mapto=>'none'},
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
		{ title=>'Фотография', mapto=>'picture_13', quote=>1},
		{ title=>'Фотография', mapto=>'picture_14', quote=>1},
		{ title=>'Фотография', mapto=>'picture_15', quote=>1},
		{ title=>'0-12 мес.', mapto=>'none' },
		{ title=>'0-3 лет', mapto=>'none' },
		{ title=>'1-11 лет', mapto=>'none' },
		{ title=>'1-2 лет', mapto=>'none' },
		{ title=>'1-6 лет', mapto=>'none' },
		{ title=>'1.5-6 лет', mapto=>'none' },
		{ title=>'2-10 лет', mapto=>'none' },
		{ title=>'2-14 лет', mapto=>'none' },
		{ title=>'2-18 мес.', mapto=>'none' },
		{ title=>'2-3 года', mapto=>'none' },
		{ title=>'2-8 лет', mapto=>'none' },
		{ title=>'3-13 лет', mapto=>'none' },
		{ title=>'3-24 мес.', mapto=>'none' },
		{ title=>'3-5 лет', mapto=>'none' },
		{ title=>'3-6 лет', mapto=>'none' },
		{ title=>'3мес.-3лет', mapto=>'none' },
		{ title=>'4-14 лет', mapto=>'none' },
		{ title=>'4-16 лет', mapto=>'none' },
		{ title=>'4-18 мес.', mapto=>'none' },
		{ title=>'4-6 лет', mapto=>'none' },
		{ title=>'4-8 лет', mapto=>'none' },
		{ title=>'5-15 лет', mapto=>'none' },
		{ title=>'5-8 мес.', mapto=>'none' },
		{ title=>'5-9 лет', mapto=>'none' },
		{ title=>'6-16 лет', mapto=>'none' },
		{ title=>'7-10 лет', mapto=>'none' },
		{ title=>'7-12 лет', mapto=>'none' },
		{ title=>'9-24 мес.', mapto=>'none' },
		{ title=>'9мес.-2 лет', mapto=>'none' },
		{ title=>'UK0-16', mapto=>'none' },
		{ title=>'Длина стопы 10,5-13,5 см', mapto=>'none' },
		{ title=>'Длина стопы 10.5см-13.5 см', mapto=>'none' },
		{ title=>'Длина стопы 11.5см-13.5 cm', mapto=>'none' },
		{ title=>'Длина стопы 12.5см-16.1см', mapto=>'none' },
		{ title=>'Длина стопы 12.8см-15.2см', mapto=>'none' },
		{ title=>'Длина стопы 12см-14см', mapto=>'none' },
		{ title=>'Длина стопы 13.4см-15.8см', mapto=>'none' },
		{ title=>'Длина стопы 13.4см-16.4см ', mapto=>'none' },
		{ title=>'Длина стопы 13.5-17см', mapto=>'none' },
		{ title=>'Длина стопы 14-16.5см', mapto=>'none' },
		{ title=>'Длина стопы 15-20см', mapto=>'none' },
		{ title=>'Длина стопы 15-22см', mapto=>'none' },
		{ title=>'Единый размер', mapto=>'none' },
		{ title=>'Размер', mapto=>'none' },
		{ title=>'Размер 0,5-2 года', mapto=>'none' },
		{ title=>'Размер 0,5-3 года', mapto=>'none' },
		{ title=>'Размер 0-3', mapto=>'none' },
		{ title=>'Размер 0-3 года', mapto=>'none' },
		{ title=>'Размер 1,5-3 года', mapto=>'none' },
		{ title=>'Размер 1,5-5 лет', mapto=>'none' },
		{ title=>'Размер 1,5-6 лет', mapto=>'none' },
		{ title=>'Размер 1,5-7 лет', mapto=>'none' },
		{ title=>'Размер 1-12 лет', mapto=>'none' },
		{ title=>'Размер 1-2 года', mapto=>'none' },
		{ title=>'Размер 1-2,5 года', mapto=>'none' },
		{ title=>'Размер 1-3 года', mapto=>'none' },
		{ title=>'Размер 1-3 года', mapto=>'none' },
		{ title=>'Размер 1-4 года', mapto=>'none' },
		{ title=>'Размер 1-4 года', mapto=>'none' },
		{ title=>'Размер 1-5 лет', mapto=>'none' },
		{ title=>'Размер 1-5 лет', mapto=>'none' },
		{ title=>'Размер 1-5 лет', mapto=>'none' },
		{ title=>'Размер 1-5 лет', mapto=>'none' },
		{ title=>'Размер 1-6 лет', mapto=>'none' },
		{ title=>'Размер 1-6 лет', mapto=>'none' },
		{ title=>'Размер 1-6 лет', mapto=>'none' },
		{ title=>'Размер 12-18', mapto=>'none' },
		{ title=>'Размер 18-28', mapto=>'none' },
		{ title=>'Размер 2 года', mapto=>'none' },
		{ title=>'Размер 2-10 лет', mapto=>'none' },
		{ title=>'Размер 2-14 лет', mapto=>'none' },
		{ title=>'Размер 2-4 лет', mapto=>'none' },
		{ title=>'Размер 2-6 лет', mapto=>'none' },
		{ title=>'Размер 2-7 лет', mapto=>'none' },
		{ title=>'Размер 2-7 лет', mapto=>'none' },
		{ title=>'Размер 2-8 лет', mapto=>'none' },
		{ title=>'Размер 2-8 лет', mapto=>'none' },
		{ title=>'Размер 2-9 лет', mapto=>'none' },
		{ title=>'Размер 24-35', mapto=>'none' },
		{ title=>'Размер 24-37', mapto=>'none' },
		{ title=>'Размер 25-30', mapto=>'none' },
		{ title=>'Размер 25-31 ', mapto=>'none' },
		{ title=>'Размер 25-32', mapto=>'none' },
		{ title=>'Размер 25-34', mapto=>'none' },
		{ title=>'Размер 25-35', mapto=>'none' },
		{ title=>'Размер 25-36', mapto=>'none' },
		{ title=>'Размер 25-37', mapto=>'none' },
		{ title=>'Размер 26-30', mapto=>'none' },
		{ title=>'Размер 26-31', mapto=>'none' },
		{ title=>'Размер 26-32', mapto=>'none' },
		{ title=>'Размер 26-34', mapto=>'none' },
		{ title=>'Размер 27-34', mapto=>'none' },
		{ title=>'Размер 27-36', mapto=>'none' },
		{ title=>'Размер 28-34', mapto=>'none' },
		{ title=>'Размер 28-36', mapto=>'none' },
		{ title=>'Размер 28-36 без 35', mapto=>'none' },
		{ title=>'Размер 28-38', mapto=>'none' },
		{ title=>'Размер 28-40', mapto=>'none' },
		{ title=>'Размер 29-35', mapto=>'none' },
		{ title=>'Размер 29-36', mapto=>'none' },
		{ title=>'Размер 3-24 мес ', mapto=>'none' },
		{ title=>'Размер 3-7 лет', mapto=>'none' },
		{ title=>'Размер 3-8 лет', mapto=>'none' },
		{ title=>'Размер 30-35', mapto=>'none' },
		{ title=>'Размер 30-37', mapto=>'none' },
		{ title=>'Размер 30-40', mapto=>'none' },
		{ title=>'Размер 30-40 четные', mapto=>'none' },
		{ title=>'Размер 30-42', mapto=>'none' },
		{ title=>'Размер 31-36', mapto=>'none' },
		{ title=>'Размер 31-37', mapto=>'none' },
		{ title=>'Размер 34-38', mapto=>'none' },
		{ title=>'Размер 34-39', mapto=>'none' },
		{ title=>'Размер 35-38', mapto=>'none' },
		{ title=>'Размер 35-39', mapto=>'none' },
		{ title=>'Размер 35-40', mapto=>'none' },
		{ title=>'Размер 35-41', mapto=>'none' },
		{ title=>'Размер 35-42', mapto=>'none' },
		{ title=>'Размер 35-44', mapto=>'none' },
		{ title=>'Размер 35-46', mapto=>'none' },
		{ title=>'Размер 36-39', mapto=>'none' },
		{ title=>'Размер 36-40', mapto=>'none' },
		{ title=>'Размер 36-41', mapto=>'none' },
		{ title=>'Размер 36-42', mapto=>'none' },
		{ title=>'Размер 36-46', mapto=>'none' },
		{ title=>'Размер 38-43', mapto=>'none' },
		{ title=>'Размер 38-44', mapto=>'none' },
		{ title=>'Размер 38-45', mapto=>'none' },
		{ title=>'Размер 39-44', mapto=>'none' },
		{ title=>'Размер 39-44', mapto=>'none' },
		{ title=>'Размер 39-45', mapto=>'none' },
		{ title=>'Размер 39-46', mapto=>'none' },
		{ title=>'Размер 4-10 лет', mapto=>'none' },
		{ title=>'Размер 4-10 лет', mapto=>'none' },
		{ title=>'Размер 4-12 лет', mapto=>'none' },
		{ title=>'Размер 4-13 лет', mapto=>'none' },
		{ title=>'Размер 4-8 лет', mapto=>'none' },
		{ title=>'Размер 40-44', mapto=>'none' },
		{ title=>'Размер 40-45', mapto=>'none' },
		{ title=>'Размер 40-46', mapto=>'none' },
		{ title=>'Размер 40-47', mapto=>'none' },
		{ title=>'Размер 41', mapto=>'none' },
		{ title=>'Размер 41-45', mapto=>'none' },
		{ title=>'Размер 41-46', mapto=>'none' },
		{ title=>'Размер 41-47', mapto=>'none' },
		{ title=>'Размер 46-58', mapto=>'none' },
		{ title=>'Размер 5-10 лет', mapto=>'none' },
		{ title=>'Размер 5-12 лет', mapto=>'none' },
		{ title=>'Размер 5-16 лет', mapto=>'none' },
		{ title=>'Размер 5-6 лет', mapto=>'none' },
		{ title=>'Размер 5-8', mapto=>'none' },
		{ title=>'Размер 5-8 лет', mapto=>'none' },
		{ title=>'Размер 5-9 лет', mapto=>'none' },
		{ title=>'Размер 6-8 лет', mapto=>'none' },
		{ title=>'Размер 8-12', mapto=>'none' },
		{ title=>'Размер 8-14 лет', mapto=>'none' },
		{ title=>'Размер 9 -24 месяца', mapto=>'none' },
		{ title=>'Размер 9 мес-3 года', mapto=>'none' },
		{ title=>'Размер L', mapto=>'none' },
		{ title=>'Размер L-XL', mapto=>'none' },
		{ title=>'Размер L-XXL', mapto=>'none' },
		{ title=>'Размер L-XXXL', mapto=>'none' },
		{ title=>'Размер M-L', mapto=>'none' },
		{ title=>'Размер M-XL', mapto=>'none' },
		{ title=>'Размер M-XXL', mapto=>'none' },
		{ title=>'Размер M-XXXL', mapto=>'none' },
		{ title=>'Размер M-XXXXL', mapto=>'none' },
		{ title=>'Размер S', mapto=>'none' },
		{ title=>'Размер S-L', mapto=>'none' },
		{ title=>'Размер S-M', mapto=>'none' },
		{ title=>'Размер S-XL', mapto=>'none' },
		{ title=>'Размер S-XXL', mapto=>'none' },
		{ title=>'Размер S-XXXL', mapto=>'none' },
		{ title=>'Размер XL-XXL', mapto=>'none' },
		{ title=>'Размер XL-XXXL', mapto=>'none' },
		{ title=>'Размер XS-L', mapto=>'none' },
		{ title=>'Размер XS-M', mapto=>'none' },
		{ title=>'Размер XS-XL', mapto=>'none' },
		{ title=>'Размер XS-XXL', mapto=>'none' },
		{ title=>'Размер пакета', mapto=>'none' },
		{ title=>'Размерные ряды', mapto=>'none' },
		{ title=>'Размерный ряд', mapto=>'none' },
		{ title=>'Размеры', mapto=>'none' },
		{ title=>'Размеры 25-29', mapto=>'none' },
		{ title=>'Размеры 32-36', mapto=>'none' },
		{ title=>'Размеры 32B-36B', mapto=>'none' },
		{ title=>'Размеры 37-45', mapto=>'none' },
		{ title=>'Размеры пакетов', mapto=>'none' },
		{ title=>'Рост 100-130 см', mapto=>'none' },
		{ title=>'Рост 100-140 см', mapto=>'none' },
		{ title=>'Рост 100-170 см', mapto=>'none' },
		{ title=>'Рост 110-130 см', mapto=>'none' },
		{ title=>'Рост 110-155 см', mapto=>'none' },
		{ title=>'Рост 50-62 см', mapto=>'none' },
		{ title=>'Рост 62-86 см', mapto=>'none' },
		{ title=>'Рост 74-98 см', mapto=>'none' },
		{ title=>'Рост 80-120 см', mapto=>'none' },
		{ title=>'Рост 80-134 см', mapto=>'none' },
		{ title=>'Рост 80-95 см', mapto=>'none' },
		{ title=>'Рост 90-140 см', mapto=>'none' },
		{ title=>'Рост 90-95 см', mapto=>'none' },
		{ title=>'Рост 95', mapto=>'none' },
		{ title=>'Рост 95-140 см', mapto=>'none' },
		{ title=>'Рост 98-164 см', mapto=>'none' },
		{ title=>'Рост110-130см', mapto=>'none' },
		{ title=>'Рост110-140см', mapto=>'none' },

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

sub convert_picture {
	unless (system("\"$constants{General}{IM}\\convert.exe\"", @_)==0){
		die "Error converting file!";
	}
}

