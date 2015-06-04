use strict;
use warnings;

use utf8;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Album;

use Encode qw( encode );
use File::Path;



start();

# -----------------------------------------------

sub start {
	my $dbh = get_dbh();
	
	my @albums = Album->new->selectAll($dbh);
	
	foreach my $album (@albums){
		process_album($dbh, $album);
	}
	
	print "Done!\n";
	
	release_dbh($dbh);
}

sub process_album {
	my ($dbh, $album) = @_;
	
	my $name = $album->get("Name");
	
	print "Processing album $name\n";
	
	my $path = "output/$name";
	my $photodir = 'products_pictures';
	my $photopath = $path.'/'.$photodir;
	unless(-e $photopath){
		mkpath($photopath);
	}
	
	my $photos = $album->getPhotos($dbh);
	
	my @data = (
		{name=>$name, suppress_defaults=>1}
	);
	
	$photopath =~ s#/#\\#g;
	
	foreach my $photo (@$photos){
		
		my @list;
		my $photoid = $photo->ID;
		my $photoname = $photo->get('Name');;
		my $file = $photo->getStoragePath();
		
		# info
		my $info_name = sprintf('iscl%08d.jpg', $photoid);
		convert_picture($file, "-resize", '"300>"', "$photopath\\$info_name");
		push @list, $info_name;
		
		# thumbnail
		my $th_name = sprintf('iscl%08d_th.jpg', $photoid);
		convert_picture($file, "-resize", '"200x150>"', "$photopath\\$th_name");
		push @list, $th_name;

		# org - just convert
		my $org_name = sprintf('iscl%08d_enl.jpg', $photoid);
		convert_picture($file, "$photopath\\$org_name");
		push @list, $org_name;

		my $str = join ',', @list;

		my $pdata = {
			code => "PW-$photoid",
			name => $photoname,
			picture_1 => $str
		};

		push @data, $pdata;
		
	}
	make_csv($path, \@data);
	print "Processed ", scalar @$photos, " photos\n";
	
}

sub make_csv {
	my ($path, $dataref) = @_;
	
	my $result_ref = webassyst_provider($dataref);
	open (CSV, '>', "$path/export.csv") or die "Cannot open file: $!";
		
	foreach my $line (@$result_ref){
		$line = encode('cp1251', $line, Encode::FB_DEFAULT);
		$line =~ s/\?//g;
		print CSV $line, "\n";
	}
	
	close CSV;
	
}

sub convert_picture {
	unless (system("\"$constants{Output}{IM}\\convert.exe\"", @_)==0){
		die "Error converting file!";
	}
}

sub webassyst_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'Артикул', mapto=>'code', force_quote=>1},
		{ title=>'Наименование (Русский)', mapto=>'name'},
		{ title=>'Наименование (English)', mapto=>'name_en'},
		{ title=>'"ID страницы (часть URL; используется в ссылках на эту страницу)"', mapto=>'page_id'},
		{ title=>'Цена', mapto=>'price', default=>'0.01'},
		
		{ title=>'Название вида налогов', mapto=>'none' },
		{ title=>'Скрытый', mapto=>'none' },
		{ title=>'Можно купить', mapto=>'none', default=>1 },
		{ title=>'Старая цена', mapto=>'none', default=>0 },
		{ title=>'Продано', mapto=>'none', default=>0 },
		{ title=>'Дата добавления', mapto=>'none' },
		{ title=>'Доп. категории', mapto=>'none' },
		
		{ title=>'Описание (Русский)', mapto=>'description', quote=>1},
		{ title=>'Описание (English)', mapto=>'description_en', quote=>1},

		{ title=>'Краткое описание (Русский)', mapto=>'none' },
		{ title=>'Краткое описание (English)', mapto=>'none' },
		{ title=>'Сортировка', mapto=>'none', default=>0 },
		{ title=>'Заголовок страницы (Русский)', mapto=>'none' },
		{ title=>'Заголовок страницы (English)', mapto=>'none' },
		{ title=>'Тэг META keywords (Русский)', mapto=>'none' },
		{ title=>'Тэг META keywords (English)', mapto=>'none' },
		{ title=>'Тэг META description (Русский)', mapto=>'none' },
		
		{ title=>'Тэг META description (English)', mapto=>'none' },
		{ title=>'Стоимость упаковки', mapto=>'none', default=>0 },
		{ title=>'Вес продукта', mapto=>'none', default=>0 },
		{ title=>'Бесплатная доставка', mapto=>'none', default=>0 },
		{ title=>'Ограничение на минимальный заказ продукта (штук)', mapto=>'none', default=>1 },
		{ title=>'Файл продукта;Количество дней для скачивания', mapto=>'none', default=>5 },
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
		

		{ title=>'UK0-16 (Русский)', mapto=>'none' },
		{ title=>'UK0-16 (English)', mapto=>'none' },
		{ title=>'Длина стопы 10,5-13,5 см (Русский)', mapto=>'none' },
		{ title=>'Длина стопы 10,5-13,5 см (English)', mapto=>'none' },
		{ title=>'Единый размер (Русский)', mapto=>'none' },
		{ title=>'Единый размер (English)', mapto=>'none' },
		{ title=>'Размер (Русский)', mapto=>'none' },
		{ title=>'Размер (English)', mapto=>'none' },
		{ title=>'Размер 0,5-2 года (Русский)', mapto=>'none' },
		{ title=>'Размер 0,5-2 года (English)', mapto=>'none' },
		{ title=>'Размер 0,5-3 года (Русский)', mapto=>'none' },
		{ title=>'Размер 0,5-3 года (English)', mapto=>'none' },
		{ title=>'Размер 0-3 года (Русский)', mapto=>'none' },
		{ title=>'Размер 0-3 года (English)', mapto=>'none' },

		{ title=>'Размер 1,5-5 лет (Русский)', mapto=>'none' },
		{ title=>'Размер 1,5-5 лет (English)', mapto=>'none' },
		{ title=>'Размер 1,5-7 лет (Русский', mapto=>'none' },
		{ title=>'Размер 1,5-7 лет (English)', mapto=>'none' },
		{ title=>'Размер 1-12 лет (Русский)', mapto=>'none' },
		{ title=>'Размер 1-12 лет (English)', mapto=>'none' },
		{ title=>'Размер 1-2 года (Русский)', mapto=>'none' },
		{ title=>'Размер 1-2 года (English)', mapto=>'none' },
		{ title=>'Размер 1-2,5 года (Русский)', mapto=>'none' },
		{ title=>'Размер 1-2,5 года (English)', mapto=>'none' },
		{ title=>'Размер 1-3 года (Русский)', mapto=>'none' },
		
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },
		{ title=>'', mapto=>'none' },

		{ title=>'Размер 1-3 года (English)', mapto=>'none'},
		{ title=>'Размер 1-4 года (Русский)', mapto=>'none'},
		{ title=>'Размер 1-4 года (English)', mapto=>'none'},
		{ title=>'Размер 1-4 года (Русский)', mapto=>'none'},
		{ title=>'Размер 1-4 года (English)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (English)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (English)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 1-5 лет (English)', mapto=>'none'},
		{ title=>'Размер 1-6 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 1-6 лет (English)', mapto=>'none'},
		{ title=>'Размер 1-6 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 1-6 лет (English)', mapto=>'none'},
		{ title=>'Размер 12-18 (Русский)', mapto=>'none'},
		{ title=>'Размер 12-18 (English)', mapto=>'none'},
		{ title=>'Размер 18-28 (Русский)', mapto=>'none'},
		{ title=>'Размер 18-28 (English)', mapto=>'none'},
		{ title=>'Размер 2 года (Русский)', mapto=>'none'},
		{ title=>'Размер 2 года (English)', mapto=>'none'},
		{ title=>'Размер 2-10 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-10 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-14 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-14 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-4 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-4 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-6 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-6 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-7 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-7 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 2-9 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 2-9 лет (English)', mapto=>'none'},
		{ title=>'Размер 24-35 (Русский)', mapto=>'none'},
		{ title=>'Размер 24-35 (English)', mapto=>'none'},
		{ title=>'Размер 25-34 (Русский)', mapto=>'none'},
		{ title=>'Размер 25-34 (English)', mapto=>'none'},
		{ title=>'Размер 26-31 (Русский)', mapto=>'none'},
		{ title=>'Размер 26-31 (English)', mapto=>'none'},
		{ title=>'Размер 27-34 (Русский)', mapto=>'none'},
		{ title=>'Размер 27-34 (English)', mapto=>'none'},
		{ title=>'Размер 28-34 (Русский)', mapto=>'none'},
		{ title=>'Размер 28-34 (English)', mapto=>'none'},
		{ title=>'Размер 28-38 (Русский)', mapto=>'none'},
		{ title=>'Размер 28-38 (English)', mapto=>'none'},
		{ title=>'Размер 29-36 (Русский)', mapto=>'none'},
		{ title=>'Размер 29-36 (English)', mapto=>'none'},
		{ title=>'Размер 3-24 мес  (Русский)', mapto=>'none'},
		{ title=>'Размер 3-24 мес  (English)', mapto=>'none'},
		{ title=>'Размер 3-7 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 3-7 лет (English)', mapto=>'none'},
		{ title=>'Размер 3-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 3-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 30-40 (Русский)', mapto=>'none'},
		{ title=>'Размер 30-40 (English)', mapto=>'none'},
		{ title=>'Размер 34-38 (Русский)', mapto=>'none'},
		{ title=>'Размер 34-38 (English)', mapto=>'none'},
		{ title=>'Размер 34-39 (Русский)', mapto=>'none'},
		{ title=>'Размер 34-39 (English)', mapto=>'none'},
		{ title=>'Размер 35-39 (Русский)', mapto=>'none'},
		{ title=>'Размер 35-39 (English)', mapto=>'none'},
		{ title=>'Размер 35-41 (Русский)', mapto=>'none'},
		{ title=>'Размер 35-41 (English)', mapto=>'none'},
		{ title=>'Размер 35-44 (Русский)', mapto=>'none'},
		{ title=>'Размер 35-44 (English)', mapto=>'none'},
		{ title=>'Размер 36-39 (Русский)', mapto=>'none'},
		{ title=>'Размер 36-39 (English)', mapto=>'none'},
		{ title=>'Размер 36-40 (Русский)', mapto=>'none'},
		{ title=>'Размер 36-40 (English)', mapto=>'none'},
		{ title=>'Размер 38-45 (Русский)', mapto=>'none'},
		{ title=>'Размер 38-45 (English)', mapto=>'none'},
		{ title=>'Размер 39-44 (Русский)', mapto=>'none'},
		{ title=>'Размер 39-44 (English)', mapto=>'none'},
		{ title=>'Размер 39-46 (Русский)', mapto=>'none'},
		{ title=>'Размер 39-46 (English)', mapto=>'none'},
		{ title=>'Размер 4-10 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 4-10 лет (English)', mapto=>'none'},
		{ title=>'Размер 4-10 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 4-10 лет (English)', mapto=>'none'},
		{ title=>'Размер 4-12 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 4-12 лет (English)', mapto=>'none'},
		{ title=>'Размер 4-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 4-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 40-46 (Русский)', mapto=>'none'},
		{ title=>'Размер 40-46 (English)', mapto=>'none'},
		{ title=>'Размер 41-45 (Русский)', mapto=>'none'},
		{ title=>'Размер 41-45 (English)', mapto=>'none'},
		{ title=>'Размер 5-12 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 5-12 лет (English)', mapto=>'none'},
		{ title=>'Размер 5-16 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 5-16 лет (English)', mapto=>'none'},
		{ title=>'Размер 5-6 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 5-6 лет (English)', mapto=>'none'},
		{ title=>'Размер 5-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 5-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 6-8 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 6-8 лет (English)', mapto=>'none'},
		{ title=>'Размер 8-12 (Русский)', mapto=>'none'},
		{ title=>'Размер 8-12 (English)', mapto=>'none'},
		{ title=>'Размер 8-14 лет (Русский)', mapto=>'none'},
		{ title=>'Размер 8-14 лет (English)', mapto=>'none'},
		{ title=>'Размер 9 мес-3 года (Русский)', mapto=>'none'},
		{ title=>'Размер 9 мес-3 года (English)', mapto=>'none'},
		{ title=>'Размер L (Русский)', mapto=>'none'},
		{ title=>'Размер L (English)', mapto=>'none'},
		{ title=>'Размер L-XL (Русский)', mapto=>'none'},
		{ title=>'Размер L-XL (English)', mapto=>'none'},
		{ title=>'Размер L-XXL (Русский)', mapto=>'none'},
		{ title=>'Размер L-XXL (English)', mapto=>'none'},
		{ title=>'Размер L-XXXL (Русский)', mapto=>'none'},
		{ title=>'Размер L-XXXL (English)', mapto=>'none'},
		{ title=>'Размер M-L (Русский)', mapto=>'none'},
		{ title=>'Размер M-L (English)', mapto=>'none'},
		{ title=>'Размер M-XL (Русский)', mapto=>'none'},
		{ title=>'Размер M-XL (English)', mapto=>'none'},
		{ title=>'Размер M-XXL (Русский)', mapto=>'none'},
		{ title=>'Размер M-XXL (English)', mapto=>'none'},
		{ title=>'Размер M-XXXL (Русский)', mapto=>'none'},
		{ title=>'Размер M-XXXL (English)', mapto=>'none'},
		{ title=>'Размер S-L (Русский)', mapto=>'none'},
		{ title=>'Размер S-L (English)', mapto=>'none'},
		{ title=>'Размер S-XL (Русский)', mapto=>'none'},
		{ title=>'Размер S-XL (English)', mapto=>'none'},
		{ title=>'Размер S-XXL (Русский)', mapto=>'none'},
		{ title=>'Размер S-XXL (English)', mapto=>'none'},
		{ title=>'Размер XL-XXL (Русский)', mapto=>'none'},
		{ title=>'Размер XL-XXL (English)', mapto=>'none'},
		{ title=>'Размер XL-XXXL (Русский)', mapto=>'none'},
		{ title=>'Размер XL-XXXL (English)', mapto=>'none'},
		{ title=>'Размер XS-L (Русский)', mapto=>'none'},
		{ title=>'Размер XS-L (English)', mapto=>'none'},
		{ title=>'Рост 100-140 см (Русский)', mapto=>'none'},
		{ title=>'Рост 100-140 см (English)', mapto=>'none'},
		{ title=>'Рост 110-130 см (Русский)', mapto=>'none'},
		{ title=>'Рост 110-130 см (English)', mapto=>'none'},
		{ title=>'Рост 50-62 см (Русский)', mapto=>'none'},
		{ title=>'Рост 50-62 см (English)', mapto=>'none'},
		{ title=>'Рост 62-86 см (Русский)', mapto=>'none'},
		{ title=>'Рост 62-86 см (English)', mapto=>'none'},
		{ title=>'Рост 74-98 см (Русский)', mapto=>'none'},
		{ title=>'Рост 74-98 см (English)', mapto=>'none'},
		{ title=>'Рост 80-120 см (Русский)', mapto=>'none'},
		{ title=>'Рост 80-120 см (English)', mapto=>'none'},
		{ title=>'Рост 86-128 см (Русский)', mapto=>'none'},
		{ title=>'Рост 86-128 см (English)', mapto=>'none'},
		{ title=>'Рост 90-140 см (Русский)', mapto=>'none'},
		{ title=>'Рост 90-140 см (English)', mapto=>'none'},
		{ title=>'Рост 95 (Русский)', mapto=>'none'},
		{ title=>'Рост 95 (English)', mapto=>'none'},
		{ title=>'Рост 95-140 см (Русский)', mapto=>'none'},
		{ title=>'Рост 95-140 см (English)', mapto=>'none'},

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
