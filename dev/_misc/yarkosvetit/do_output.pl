use strict;
use warnings;

use utf8;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;


use Category;
use Product;
use Property;
use ProductPicture;

use File::Path;
use Encode qw(encode decode);

our $output = 'output';

#our $output_pictures = $output . '/pictures';
#our $output_pictures_800 = $output . '/pictures/800';
#our $output_pictures_150 = $output . '/pictures/150';

#unless (-e $output_pictures_800 && -d $output_pictures_800){
#	mkpath($output_pictures_800);
#}
#
#unless (-e $output_pictures_150 && -d $output_pictures_150){
#	mkpath($output_pictures_150);
#}


our $dbh = get_dbh();

process_vendor($_) foreach ("Altalusse (Чехия)", "Arte Lamp (Италия)", "Eglo (Австрия)", "Globo (Австрия)", "Lussole (Италия)", "MarkSlojd (Швеция)", "Nlight (Италия)", "Odeon Light (Италия)", "ST Luce (Италия)");

#process_vendor($_) foreach ("Altalusse (Чехия)", "Arte Lamp (Италия)");


release_dbh($dbh);



exit;



sub process_vendor {
	my $vendor = shift;
	
	print Encode::encode('cp-866', $vendor), "\n";
	
	my $vname = $vendor;
	$vname =~ s/ \(.+//;
	
	my $output_vendor = $output . '/' . $vname;
	my $output_pictures_800 = $output_vendor . '/pictures/800';
	my $output_pictures_150 = $output_vendor . '/pictures/150';
	unless (-e $output_pictures_800 && -d $output_pictures_800){
		mkpath($output_pictures_800);
	}
	unless (-e $output_pictures_150 && -d $output_pictures_150){
		mkpath($output_pictures_150);
	}
	
	my @collector;
	
	my $c_obj = Category->new;
	$c_obj->set('Name', $vendor);
	$c_obj->select($dbh);
	
	my $p_obj = Product->new;
	$p_obj->markDone();
	$p_obj->set('Category_ID', $c_obj->ID);
	
	#$p_obj->maxReturn(10);
	
	my @products = $p_obj->listSelect($dbh);
	
	print scalar @products, " products\n";
	
	foreach my $prod (@products){
		
		my $item = {
			code => $prod->get('InternalID'),
			name => $prod->get('Name'),
			vendor => $vendor,
			price => $prod->get('Price'),
			#description => $prod->get('Description'),
		};
		
		# extract properties
		my $prop_obj = Property->new;
		$prop_obj->set('Product_ID', $prod->ID);
		my @plist = $prop_obj->listSelect($dbh);
		$item->{ $_->get("Name") } = $_->get("Value") foreach @plist;
		
		# check picture
		my $pic_obj = ProductPicture->new;
		$pic_obj->set('Product_ID', $prod->ID);
		$pic_obj->markDone();
		if($pic_obj->checkExistence($dbh)){
			
			my $orgname = $pic_obj->getOrgName();
			$orgname =~ s/(.+)\..+/$1.jpg/;
			
			print "Image $orgname (", $pic_obj->ID, ")\n";
			
			my $path_800 = $output_pictures_800 . '/' . $orgname;
			my $path_150 = $output_pictures_150 . '/' . $orgname;
			
			$item->{photo} = "c:\\$orgname";
			
			unless (-e $path_800) {
				my $src = $pic_obj->getStoragePath();
				
				# resize to 800x800
				my $cmd = "d:\\tools\\ImageMagick\\convert.exe -resize \"800x800>\" \"$src\" tmp.bmp";
				`$cmd`;
				
				# composite to 800 output
				$cmd = "d:\\tools\\ImageMagick\\composite.exe -gravity center tmp.bmp white.bmp \"$path_800\"";
				`$cmd`;
				
				# resize to 150
				$cmd = "d:\\tools\\ImageMagick\\convert.exe -resize \"150x150>\" \"$path_800\" \"$path_150\"";
				`$cmd`;
			}
			
			
			
		} # if exists picture
		
		push @collector, $item;
	}
	
	save_csv("$output_vendor/output.csv", \@collector, 'cp-1251');
}


sub save_csv {
	my ($name, $data_ref, $encoding) = @_;
	$encoding ||= 'cp1251';
	
	my $result_ref = data_provider($data_ref);
	
	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";
		
	foreach my $line (@$result_ref){
		$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	
	close CSV;
}


sub data_provider {

	my $data_ref = shift;
	
	my @all_columns_ru = (
		{ title=>'Код товара', mapto=>'code'},
		{ title=>'Название товара', mapto=>'name', force_quote=>1},
		{ title=>'Бренд', mapto=>'vendor', force_quote=>1},
		{ title=>'Цена', mapto=>'price', force_quote=>1},
		{ title=>'Фото', mapto=>'photo', force_quote=>1},
		#{ title=>'Описание', mapto=>'description', force_quote=>1},
	);
	
	# get additional columns
	my @rows = ISoft::DB::do_query($dbh, sql=>"select distinct `Name` from `Property`");
	push @all_columns_ru, {title=>$_, mapto=>$_, force_quote=>1} foreach map { $_->{Name} } @rows;
	
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
