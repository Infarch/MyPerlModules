use strict;
use warnings;
use utf8;

use threads;
use threads::shared;

use DBI;
use Encode qw( encode );
use Error ':try';
use File::Path;
use LWP::UserAgent;
use Thread::Queue;


use Browsers;
use NameProvider;
use SimpleConfig;


# look for arguments
my $mode = $ARGV[0] || '';
if ($mode eq 'output'){
	do_output();
} else {
	parse($mode);
}

print "\nDone\n";

exit;

# ------------------------------------------------

sub do_output {
	
	# check existence of output dir
	my $dir = $constants{Parser}{OutputDir};
	if(!-e $dir || !-d $dir){
		mkpath($dir);
	}
	
	
	my $code = $constants{User}{Code};
	die "No product code" unless $code;
	
	my $dbh = get_dbh();
	
	my $start = $constants{User}{StartFrom};
	
	my $photolist = get_photo_list($dbh);
	
	my $max_pic_number = apply_groups($photolist);
	if($max_pic_number > 15){
		print "Warning: the maximal number of pictures for a product exceeded: $max_pic_number!\n";
	}
	print scalar @$photolist, " photos to be exported\n";
	
	# loop through the list, prepare data for export
	my @data = (
		# root directory for the new data
		#{name=>'New products', suppress_defaults=>1},
		# directory for the user alias
		#{name=>'!'.$constants{User}{Alias}, suppress_defaults=>1},
	);
	#my $old_id = -1;
	foreach my $row (@$photolist){
		
		next if exists $row->{Skip};
		
#		# check whether the current row belongs to new album
#		my $id = $row->{AlbumID};
#		if($id != $old_id){
#			push @data, {name=>'!!'.correct_text($row->{AlbumName}), suppress_defaults=>1};
#			$old_id = $id;
#		}
		
		my $photoid = $row->{ID};
		
		my @photos;
		if(exists $row->{Store}){
			push @photos, @{$row->{Store}};
		} else {
			push @photos, $photoid;
		}
		
		# process product
		
		my $description = correct_text($row->{Description});
		my @dparts = split /\s+/, $description;
		
		my $number = @dparts>4 ? 5 : @dparts;
		my $name = join ' ', (@dparts[0..$number-1]);
		
		my $fullcode = $code . $start++;
		print "Generating $fullcode\n";
		
		my $pdata = {
			code => $fullcode,
			name => $name,
			description => $description
		};

		my $count = 1;
		foreach my $pid (@photos){

			my @list;
			my $stored = $constants{Parser}{Photos} . "\\$pid";
				
			# info
			my $basename = "ispc_${fullcode}_$count";
			
			my $info_name = lc "$basename.jpg";
			convert_picture($stored, "-resize", '"300>"', "$constants{Parser}{OutputDir}\\$info_name");
			push @list, $info_name;
			
			# thumbnail
			my $th_name = lc "${basename}_th.jpg";
			convert_picture($stored, "-resize", '"200x150>"', "$constants{Parser}{OutputDir}\\$th_name");
			push @list, $th_name;
	
			# org - just convert
			my $org_name = lc "${basename}_enl.jpg";
			convert_picture($stored, "$constants{Parser}{OutputDir}\\$org_name");
			push @list, $org_name;
				
			my $str = join ',', @list;
			$pdata->{"picture_$count"} = $str;
			
			$count++;
		}
		
		push @data, $pdata;
		
		# mark the photo as exported
		my $sql = "update $tb_photo set Status=$st_done where ID=$photoid";
		do_query($dbh, sql=>$sql);
		
	}
	
	# save file, commit
	save_csv("export.csv", \@data);
	do_commit($dbh);
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
	unless (system("\"$constants{Parser}{IM}\\convert.exe\"", @_)==0){
		die "Error converting file!";
	}
}

sub apply_groups {
	my ($photolist) = @_;
	
	my $max_pic_number = 1;
	
	# get groups
	my %grouphash;
	my $number = 0;
	foreach my $key (keys %constants){
		my $group = $constants{$key};
		if (ref $group eq 'ARRAY'){
			foreach my $item (@$group){
				$item =~ s/^https/http/;
				$grouphash{$item} = $number;
			}
			$number++;
		}
	}
	
	return $max_pic_number unless $number;
	
	# x[<groupnumber>] = photolist index
	my @groupindex;
	my $p = 0;
	foreach my $photo (@$photolist){
		
		my $checkurl = $photo->{AlbubURL} . '#' . $photo->{GoogleID};
		$checkurl =~ s/^https/http/;
		if(exists $grouphash{$checkurl}){
			
			my $number = $grouphash{$checkurl};
			
			my $x;
			if(defined $groupindex[$number]){
				$x = $groupindex[$number];
				$photo->{Skip} = 1;
			} else {
				$groupindex[$number] = $p;
				$x = $groupindex[$number];
			}
			
			my $store = $photolist->[$x]->{Store};
			unless(defined $store){
				$store = [];
				$photolist->[$x]->{Store} = $store;
			}
			
			push @$store, $photo->{ID};
			
		}
		
		$p++;
	}
	
	# look for the bigest number
	foreach my $nn (@groupindex){
		if (defined $nn){
			my $x = @{ $photolist->[$nn]->{Store} };
			$max_pic_number = $x if $x > $max_pic_number;
		}
	}
	
	return $max_pic_number;
}

sub correct_text {
	my $string = shift;
	$string =~ s/\r|\n|\t/ /g;
	$string =~ s/"/'/g; #"
	$string =~ s/\s{2,}/ /g;
	return $string;
}

sub get_photo_list {
	my ($dbh) = @_;
	
	my $cfg = process_user_config($dbh);
	do_commit($dbh);
	
	my $uid = $cfg->{ID};
	my $albums = delete $cfg->{_albums};
	my $astr = '';
	if(defined $albums){
		$astr = join ',', map { $_->{ID} } @$albums;
		$astr = "and a.ID in ($astr)";
	}
	
	my $sql = qq(
		select a.URL as AlbubURL, p.*
		from
			$tb_user u
			join $tb_album a on a.User_ID = u.ID
			join $tb_photo p on p.Album_ID = a.ID
		where
			u.ID = $uid	$astr
	);

#	my $sql = qq(
#		select a.URL as AlbubURL, p.*
#		from
#			$tb_user u
#			join $tb_album a on a.User_ID = u.ID
#			join $tb_photo p on p.Album_ID = a.ID
#		where
#			u.Alias = '$constants{User}{Alias}'	and p.Status=$st_ready_for_export
#	);

	return do_query($dbh, sql=>$sql);
}

# ------------------------------------------------

sub new_album {
	my $dbh = shift;
	
	# get user id
	my $sql = "select ID from $tb_user where Alias=?";
	my $uid = do_query($dbh, sql=>$sql, values=>[$constants{User}{Alias}], single=>1);
	
	# read albums
	my $acfg = $constants{User}{Album};
	
	if( !defined $acfg ){
		# (if no albums in config then reload the user)
		print "All new albums\n";
		my $sql = "update $tb_user set Status=$st_new where ID=$uid";
		do_query($dbh, sql=>$sql);
	} else {
		# populate array
		my @clist;
		if(ref $acfg){
			@clist = @$acfg;
		} else {
			push @clist, $acfg;
		}
		# check existence of the albums
		foreach my $item (@clist){
			$item =~ s/^https/http/;
			$item =~ s/#$//;
			my $data = {
				User_ID => $uid,
				URL => $item
			};
			
			my $rows = do_select($dbh, $tb_album, $data);
			unless( shift @$rows ){
				# insert
				$data->{URL} = $item;
				$data->{Status} = $st_new;
				$data->{Name} = 'from_config';
				do_insert($dbh, $tb_album, $data);
			}
			
		}
		
	}
	do_commit($dbh);
}

sub do_commit {
	my $dbh = shift;
	if(!$dbh->commit() || $dbh->err) {
		die $dbh->err;
	}
}

sub check_insert_member {
	my ($dbh, $table, $data) = @_;
	
	my $mm = get_existing_member($dbh, $table, $data);
	unless( defined $mm ){
		$mm = do_insert($dbh, $table, $data);
	}
	return $mm;
}

sub correct_url {
	$_[0] =~ s/^https/http/i;
	$_[0] =~ s/#$//;
	$_[0] =~ s/\/$//;
}

sub check_insert_user_by_url {
	my ($dbh, $url) = @_;
	correct_url($url);
	$url =~ /\/([^\/]+)$/;
	my $alias = $1;
	my $userdata = {
		Alias => $alias,
		URL => $url
	};
	return check_insert_member($dbh, $tb_user, $userdata);
}

sub check_insert_album_by_url {
	my ($dbh, $user_id, $url) = @_;
	correct_url($url);
	$url =~ /\/([^\/]+)$/;
	my $userdata = {
		User_ID => $user_id,
		URL => $url
	};
	return check_insert_member($dbh, $tb_album, $userdata);
}

sub init_parsing_by_config {
	my ($dbh, $cfg) = @_;
	
	# parse the whole user?
	my $albums = delete $cfg->{_albums};
	if(defined $albums){
		# all users will not be parsed
		my $sql = "update $tb_user set Status=$st_ready_for_export where Status=$st_new";
		do_query($dbh, sql=>$sql);
		my @idlist = map {$_->{ID}} @$albums;
		my $idstr = join ',', @idlist;
		# other albums will not be parsed
		$sql = "update $tb_album set Status=$st_ready_for_export where ID not in ($idstr) and Status=$st_new";
		do_query($dbh, sql=>$sql);

		# only the specified albums will be parsed
		$sql = "update $tb_album set Status=$st_new, Errors=0 where ID in ($idstr)";
		do_query($dbh, sql=>$sql);
		
	} else {
		my $uid = $cfg->{ID};
		# other users will not be parsed
		my $sql = "update $tb_user set Status=$st_ready_for_export where ID!=$uid and Status=$st_new";
		do_query($dbh, sql=>$sql);
		# mark the specified user as New
		$sql = "update $tb_user set Status=$st_new, Errors=0 where ID=$uid";
		do_query($dbh, sql=>$sql);
		# reload also all existing user albums
		$sql = "update $tb_album set Status=$st_new, Errors=0 where User_ID=$uid";
		do_query($dbh, sql=>$sql);
	}
	
}

sub process_user_config {
	my $dbh = shift;
	
	my $userdata;
	
	# check User option
	if( exists $constants{User}{User} ){
		$userdata = check_insert_user_by_url($dbh, $constants{User}{User});
	} elsif ( exists $constants{User}{Album} ){
		my $albums = ref $constants{User}{Album} ? $constants{User}{Album} : [$constants{User}{Album}];
		# look for user. agree that all the albums belong to the same user.
		my $first_url = $albums->[0];
		correct_url($first_url);
		# remove the last part of the url - get user link
		$first_url =~ /(.+)\/([^\/]+)$/;
		$userdata = check_insert_user_by_url($dbh, $1);
		my @storage;
		# loop through albums
		foreach my $album (@$albums){
			push @storage, check_insert_album_by_url($dbh, $userdata->{ID}, $album);
		}
		$userdata->{_albums} = \@storage;
	} else {
		die "Nothing to do!!!";
	}
	return $userdata;
}

sub parse {
	my $mode = shift;
	
	my @worklist = ( $tb_user, $tb_album, $tb_photo );
	
	my $dbh = get_dbh();
	if($mode eq 'start'){
		
		# very important! way to new simple interface!
		my $cfg = process_user_config($dbh);
		init_parsing_by_config($dbh, $cfg);
		do_commit($dbh);
		
	} elsif($mode eq 'repair'){
		foreach (@worklist){
			remove_errors($dbh, $_);
		}
	} elsif ($mode eq 'newalbum'){
		print "New album(s)\n";
		new_album($dbh);
	} elsif ($mode eq 'reload'){
		print "Reload\n";
		mark_new($dbh);
	} else {
		# default mode
		#check_first_start($dbh);
	}
	release_dbh($dbh);
	
	my $queue = new Thread::Queue();
	
	foreach my $table (@worklist){
		
		prepare_environment($table);
		
		my $work = 1;
		do {
			my $memberlist = load_members($table);
			if(@$memberlist > 0){
				# push tasks to queue
				foreach my $member(@$memberlist){
					$member->{_table} = $table;
					$queue->enqueue(shared_clone($member));
				}
				# start threads
				my $count = 0;
				foreach (1..$constants{Parser}{Threads}){
					$count++ 
						if defined threads->create( 'worker', $queue );
				}
				# wait for finish
				while ($count){
					sleep 3;
					my @joinable = threads->list(threads::joinable);
					foreach my $thrd (@joinable){
						$thrd->join();
						$count--;
					}
				}
			} else {
				$work = 0;
			}
		} while ($work);
				
	}
	
	check_fails(@worklist);
	
}

sub check_fails {
	my @worklist = @_;
	my $dbh = get_dbh();
	my $total = 0;
	foreach my $obj (@worklist){
		my $sql = "select count(*) from $obj where Status=$st_failed";
		my $failed = do_query($dbh, sql=>$sql, single=>1);
		print "$obj: $failed failed records\n";
		$total += $failed;
	}
	if($total){
		print "$total fails total\n";
	}
	release_dbh($dbh);
	return $total;
}

sub mark_new {
	my $dbh = shift;
	my $sql = qq(
		UPDATE $tb_user, $tb_album SET $tb_user.Errors=0, $tb_album.Errors=0, $tb_user.Status=$st_new, $tb_album.Status=$st_new
		WHERE $tb_album.User_ID = $tb_user.ID AND $tb_user.Alias=?
	);
	do_query($dbh, sql=>$sql, values=>[$constants{User}{Alias}]);
	do_commit($dbh);
}

sub prepare_environment {
	my $table = shift;
	if($table eq $tb_photo){
		my $path = $constants{Parser}{Photos};
		if(!-e $path && !-d $path){
			mkpath($path);
		}
	}
}

sub load_members {
	my ($table) = @_;
	my $dbh = get_dbh();
	my $listref = do_select($dbh, $table, {Status=>$st_new}, 500);
	release_dbh($dbh);
	return $listref;
}

sub worker {
	my $queue = shift;
	my $dbh = get_dbh();
	my $agent = LWP::UserAgent->new;
	
	srand();
	
	my $member;
	while( $member = $queue->dequeue_nb() ){
		process_member($dbh, $agent, $member);
	}
	
	release_dbh($dbh);
}

sub process_member {
	my ($dbh, $agent, $member) = @_;
	
	my $table = delete $member->{_table};
	my $oldstatus = $member->{Status};
	
	try {
		my $url = $member->{URL};
		$url =~ s/^https/http/;
		# set up user agent
		my $number = int (rand(@browsers));
		my $xx = $browsers[$number];
		$agent->agent($xx);
		# get
		my $response = $agent->get($url);
		if($response->is_success()){
			
			print "$url\n";
			
			$member->{Status} = $st_ready_for_export;
			
			if($table eq $tb_user){
				process_user($dbh, $response, $member);
			} elsif($table eq $tb_album){
				process_album($dbh, $response, $member);
			} elsif($table eq $tb_photo){
				process_photo($dbh, $response, $member);
			} else {
				die "Handler for $table is not implemented";
			}
			do_update($dbh, $table, $member);
			
		} else {
			die "Request failed: ", $response->status_line();
		}
		
	} otherwise {
		print "An error occured:\n$@\n";
		my $errors = $member->{Errors}+1;
		if($errors==5){
			$oldstatus = $st_failed;
		}
		my $sql = "update $table set Errors=$errors, Status=$oldstatus where ID=$member->{ID}";
		do_query($dbh, sql=>$sql);
	};
	
	do_commit($dbh);
	
}

sub process_photo {
	my ($dbh, $response, $photo) = @_;
	my $path = $constants{Parser}{Photos} . "/$photo->{ID}";
	open XX, ">$path" or die "Cannot save file $path: $!";
	binmode XX;
	print XX $response->content;
	close XX;
}

sub process_album {
	my ($dbh, $response, $album) = @_;
	
	my $photos = extract_photos($response->decoded_content());
	my $count = scalar @$photos;
	unless($count){
		die "Strange, no photos!";
	}
	# insert the photos into database
	foreach my $photo (@$photos){
		$photo->{Album_ID} = $album->{ID};
		do_insert($dbh, $tb_photo, $photo)
			unless member_exists($dbh, $tb_photo, $photo);
	}
	
}

sub extract_photos {
	my ($content) = @_;
	
	if($content=~/^(feedPreload.+)$/m){
		$content = $1;
	} else {
		die "No data";
	}

	$content =~ s/"link":\[[^\]]+\],//g;
	$content =~ s/^.+?"entry":\[//;
	
	my @list;
	while ( $content=~/"title":"([^"]*)","gphoto\$id":"([^"]*)".*?"url":"([^"]*)".*?"description":"([^"]*)"/g ){
		
		my $url = $3;
		$url =~ s/^https/http/;
		
		push @list, {
			GoogleID => $2,
			URL => $url,
			Description => $4,
			FileName => $1
		};
	}

	return \@list;
}

sub process_user {
	my ($dbh, $response, $user) = @_;
	
	my $uid = $user->{ID};
	
	# extract albums
	my $albums = extract_albums($response->decoded_content());
	
	# insert albums
	foreach my $album (@$albums){
		
		my $old = get_existing_member($dbh, $tb_album, $album);
		
		if ( album_allowed($album) ) {
			$album->{User_ID} = $uid;
			do_insert($dbh, $tb_album, $album)
				unless defined $old
		} else {
			if(defined($old) && $old->{Status}==$st_new){
				$old->{Status} = $st_ready_for_export;
				do_update($dbh, $tb_album, $old);
			}
		}
		
	}
	
}

sub album_allowed {
	my $url = $_[0]->{URL};
	my $ok = 1;
	if( defined( my $check = $constants{User}{Album} ) ){
		if(ref $check){
			$ok = 0;
			foreach my $checkurl (@$check){
				$checkurl =~ s/^https/http/;
				$checkurl =~ s/#$//;
				if($url eq $checkurl){
					$ok = 1;
					last;
				}
			}
		} else {
			$check =~ s/^https/http/;
			$check =~ s/#$//;
			$ok = $url eq $check;
		}
	}
	return $ok;
}

sub extract_albums {
	my ($content) = @_;

	$content =~ s/\r|\n/ /g;
	
	my @ns = $content =~ /<noscript>(.*?)<\/noscript>/g;
	$content = $ns[1];
	my @albums = $content =~ /<div>(.*?)<\/div>/g;

	my @album_data;
	
	foreach my $album (@albums){
		
		my ($url, $title);
		if($album =~ /<a href="(.*?)"/){
			$url = $1;
			$url =~ s/^https/http/;
		}
		if($album =~ /<p>(.*?)<\/p>/){
			$title = $1;
		}
		push @album_data, {
			URL => $url,
			Name => $title,
		};
		
	}
	
	return \@album_data;
}

sub remove_errors {
	my ($dbh, $table) = @_;
	my $sql = "update $table set Errors=0, Status=$st_new where Status=$st_failed";
	do_query($dbh, sql=>$sql);
	do_commit($dbh);
}

# deprecated!!!
sub check_first_start {
	my $dbh = shift;
	
	my $root_data = {Alias=>$constants{User}{Alias}, URL=>$constants{Parser}{BaseUrl}.$constants{User}{Alias}};
	
	my $root = do_select($dbh, $tb_user, $root_data);
	if(@$root==0){
		# insert root object
		my $xxx = do_insert($dbh, $tb_user, $root_data);
		do_commit($dbh);
	}
}

sub get_existing_member {
	my ($dbh, $table, $member) = @_;
	my $sql = "select * from $table where URL=? limit 1";
	my $result = do_query($dbh, sql=>$sql, values=>[$member->{URL}]);
	return shift @$result;
}

sub member_exists {
	my ($dbh, $table, $member) = @_;
	my $sql = "select count(*) from $table where URL=?";
	my $result = do_query($dbh, sql=>$sql, values=>[$member->{URL}], single=>1);
	return $result > 0;
}

sub do_insert {
	my ($dbh, $table, $values) = @_;
	
	my @field_list;
	my @val_list;
	foreach my $field (keys %$values){
		my $value = $values->{$field};
		push @field_list, $field;
		push @val_list, $value;
	}
	
	my $hold_str = join ',', map {'?'} (0..$#val_list);
	my $field_str = join ',', @field_list;
	
	my $sql = "insert into $table ($field_str) values ($hold_str)";
	
	do_query($dbh, sql=>$sql, values=>\@val_list, single=>1);
	my $newobjlist = do_query($dbh, sql=>"select * from $table where ID=LAST_INSERT_ID()");
	return $newobjlist->[0];
}

sub do_update {
	my ($dbh, $table, $values) = @_;
	
	my @field_list;
	my @val_list;
	my $id;
	foreach my $field (keys %$values){
		my $value = $values->{$field};
		if($field eq 'ID'){
			$id = $value;
		} else {
			push @field_list, "$field=?";
			push @val_list, $value;
		}
	}
	push @val_list, $id;
	
	my $field_str = join ',', @field_list;
	
	my $sql = "update $table set $field_str where ID=?";
	
	do_query($dbh, sql=>$sql, values=>\@val_list, single=>1);
}

sub do_select {
	my ($dbh, $table, $clauses, $limit) = @_;
	
	my @field_list;
	my @val_list;
	if(defined( $clauses )){
		
		foreach my $field (keys %$clauses){
			my $value = $clauses->{$field};
			push @field_list, "$field=?";
			push @val_list, $value;
		}
	}
	
	my $cstr = join ' and ', @field_list;
	$cstr = $cstr ? "where $cstr" : "";
	my $lstr = $limit ? "limit $limit" : "";
	my $sql = "select * from $table $cstr $lstr";
	
	return do_query($dbh, sql=>$sql, values=>\@val_list); 
}

sub do_query {
	my ($dbh, %params) = @_;
	my $sql = $params{sql};
	my $hashref = exists $params{hashref} ? $params{hashref} : 0;
	my $arr_ref = exists $params{arr_ref} ? $params{arr_ref} : 0;
	my $single  = exists $params{single}  ? $params{single}  : 0;

	my @vals;
	if (exists $params{values}){
		my $rf = ref $params{values};
		if($rf && $rf eq 'ARRAY'){
			@vals = @{$params{values}};
		} else {
			die "The 'values' parameter should be an array reference";
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or die "SQL Error: ".$dbh->err()." ($sql)";
	} else {
		$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	}

	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} elsif($hashref) {
		$rows = $sth->fetchall_arrayref({});
	} elsif($arr_ref || $single) {
		$rows = $sth->fetchall_arrayref([]);
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	if($single){
		return @$rows>0 ? $rows->[0]->[0] : undef;
	}
	return $rows;
}

sub release_dbh {
	my $dbh = shift;
	$dbh->rollback();
	$dbh->disconnect();
}

sub get_dbh {
	my $dbh = DBI->connect("dbi:mysql:$constants{DB}{Base}:host=$constants{DB}{Host}", $constants{DB}{User}, $constants{DB}{Password}) or 
		die "Connection Error: $DBI::errstr\n";
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	$dbh->{AutoCommit} = 0;
	return $dbh;
}


