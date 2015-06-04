use strict;
use warnings;

use utf8;

use File::Copy;
use File::Path;
use Encode qw/encode decode/;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Product;
use Property;
use ProductPicture;
use ProductDescriptionPicture;

our $prefix = 'e_';

our $article_mask = $prefix . '%05d';

our $output = 'd:/pfiles/e96/output';
our $output_pictures = $output . '/pictures';

our %cat_cache;

unless (-e $output_pictures && -d $output_pictures){
	mkpath($output_pictures);
}


process_data();

exit;


sub process_data {
	
	my $dbh = get_dbh();
	
	my $prod_obj = Product->new;
	$prod_obj->markDone();
	#$prod_obj->maxReturn(500);
	my $prod_list = $prod_obj->listSelect($dbh);
	
	print scalar @$prod_list, " products\n";
	
	my @collector;
	
	process_product($dbh, $_, \@collector) foreach @$prod_list;
	
	release_dbh($dbh);
	
	save_csv("$output/data.csv", \@collector, 'cp-1251');
}

sub process_product {
	my ($dbh, $prod_obj, $collector) = @_;
	
	print $prod_obj->ID, "\n";
	
	my $catname = get_cat_path($dbh, $prod_obj->get('Category_ID'));
	
	my $item = {
		category => $catname,
		vendor => $prod_obj->get('Vendor'),
		name => $prod_obj->get('Name'),
		pid => $prod_obj->ID,
		description => $prod_obj->get('ShortDescription'),
		
		#price => $prod_obj->get('Price'), # don't include
		
	};
	
	# get options (properties)
	my $property = Property->new;
	$property->set('Product_ID', $prod_obj->ID);
	$property->setOrder('OrderNumber', 'asc');
	my $plist = $property->listSelect($dbh);
	
	my @props;
	foreach my $pobj (@$plist){
		
		my $group = $pobj->get('Group');
		if($group =~ /Основные характеристики/){
			$pobj->set('Group', "Основные характеристики");
		}
		
		my $nm = $pobj->Name;
		my $val = $pobj->get('Value');
		push @props, "\"$nm:[$val]\"";
	}
	$item->{options} = join ';', @props;
	
	# get images
	my @images = $prod_obj->getProductPictures($dbh);
	
	my @img_files;
	foreach my $image_obj (@images){
		next if $image_obj->get('Status') != 3;
		my $from = $image_obj->getStoragePath;
		my $orgname = $image_obj->getOrgName();
		my $to = $output_pictures . '/' . $orgname;
		push @img_files, $orgname;
		copy $from, $to;
	}
	
	$item->{files} = join ';', @img_files if @img_files > 0;
	
	push @$collector, $item;
}



sub get_cat_path {
	my ($dbh, $id) = @_;
	
	my @parts;
	
	do {
		unless ( exists $cat_cache{$id} ){
			my $c = Category->new;
			$c->set('ID', $id);
			$c->select($dbh);
			$cat_cache{$id} = $c;
		}
		
		my $obj = $cat_cache{$id};
		$id = $obj->get('Category_ID');
		unshift @parts, $obj->Name if $id; # skip root
		
	} while ($id);
	
	return join '///', @parts;
}


sub save_csv {
	my ($name, $data_ref, $encoding) = @_;
	$encoding ||= 'cp1251';
	
	my $result_ref = format_provider($data_ref);
	
	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";
		
	foreach my $line (@$result_ref){
		$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	
	close CSV;
}

sub format_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'PID', mapto=>'pid'},
		{ title=>'Category', mapto=>'category'},
		{ title=>'Vendor', mapto=>'vendor'},
		{ title=>'Name', mapto=>'name'},

		{ title=>'Description', mapto=>'description'},

#		{ title=>'Price', mapto=>'price'},

		{ title=>'Files', mapto=>'files'},
		{ title=>'Features', mapto=>'options'},
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	foreach my $column (@all_columns_ru){
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
	}
	
	my $glue_char = ";";
	
	my @output;
	
	# make header
	push @output, join ($glue_char, @header_list);
	
	# process data
	my $col_number = @map_list;
	
	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = $dataitem->{$key};
			if(defined $value){
				$value =~ s/"/""/g; #";
				$value = '"' . $value . '"';
			} else {
				$value = '';
			}
			
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	
	return \@output;
	
}
