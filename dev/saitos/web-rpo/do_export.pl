use strict;
use warnings;

#use open qw(:std :utf8);

use Error qw(:try);
use Image::Resize;
use GD::Image;
use XML::LibXML;









# load price
my $price = load_price_2('1columnprice.csv');

# make loop
# ....


# load xml
my $xml = load_xml('perfumery_and_cosmetics.xml');

# decode xml
my $data_ref = process_category($xml);

# generate images
generate_images($data_ref);

# make csv file
make_csv($data_ref, 'Perfumery and cosmetics.xml');





#################### functions ###########################

sub shopos_provider {

	my $data_ref = shift;
	
	# columns definition - ShopOS CSV format (brief, only for adding)
	my @all_columns = (
		{ title=>'v_products_id', mapto=>'none', default=>'0'},
		{ title=>'v_products_model', mapto=>'article'},
		{ title=>'v_products_image', mapto=>'image'},
		{ title=>'v_products_name_1', mapto=>'name'},
		{ title=>'v_products_description_1', mapto=>'description_full'},
		{ title=>'v_products_price', mapto=>'price', default=>'0.01'},
		{ title=>'v_products_weight', mapto=>'none', default=>'0'},
		{ title=>'v_date_added', mapto=>'none', default=>'5.08.2010 13:00'},
		{ title=>'v_products_quantity', mapto=>'none', default=>'0'},
		{ title=>'v_products_sort', mapto=>'none', default=>'0'},
		{ title=>'v_manufacturers_name', mapto=>'vendor'},
		{ title=>'v_categories_name_1', mapto=>'category'},
		{ title=>'v_tax_class_title', mapto=>'none', default=>'--нет--'},
		{ title=>'v_status', mapto=>'none', default=>'Active'},
		{ title=>'EOREOR', mapto=>'none', default=>'EOREOR'},
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	foreach my $column (@all_columns){
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
		push @defaults, exists $column->{default} ? $column->{default} : '';
	}
	my $glue_char = "\t";
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
			my $value = (exists $dataitem->{$key} && $dataitem->{$key}) ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			if ($value =~ /$glue_char/o){
				$value = '"' . $value . '"';
			}
			if ( $value =~ /"$/ ) #"
			{
				$value .= ' ';
			}
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	return \@output;
}

sub make_csv {
	my ($data_ref, $name) = @_;
	
	foreach my $item (@$data_ref){
		my $id = int($item->{id});
		my $article = sprintf("%04d", $id);
		$item->{article} = $article;
		# set product price
		my $price = $price->{ $id };
		$item->{price} = $price;
		# set category
		$item->{category} = $name;
	}
	
	open CSV, '>:encoding(UTF-8)', "export/$name.csv";
	my $result_ref = shopos_provider($data_ref);
	foreach my $line (@$result_ref){
		print CSV $line . chr(10);
	}

	close CSV;
	
}

sub generate_images {
	my $data_ref = shift;
	
	foreach my $data_item(@$data_ref){
		
		my $name = $data_item->{image};
		next unless $name;
		
		my $image;
		my $error = 0;
		
		try {
			my $imagetemp = GD::Image->newFromGif("product_images/$name");
			#$image = Image::Resize->new("product_images/$name");
			$image = Image::Resize->new($imagetemp);
		} otherwise {
			print "No image $name\n";
			$data_item->{image} = '';
			$error = 1;
		};
		
		next if $error;
		
#		$name =~ /^([^.]+)\.([^.]+)$/;
#		my $newname = $1.'.jpg';
#		$data_item->{image} = $newname;
		
		
		my $gd_th = $image->resize(170, 137);
		open (II, ">export/thumbnails/$name") or die "Cannot open image file";
		binmode II;
		print II $gd_th->gif();
		close II;
		
		my $gd_info = $image->resize(260, 210);
		open (II, ">export/info/$name") or die "Cannot open image file";
		binmode II;
		print II $gd_info->gif();
		close II;
		
		open (II, ">export/popup/$name") or die "Cannot open image file";
		binmode II;
		print II $image->gd()->gif();
		close II;

	}
		
}

sub process_category {
	my $xml = shift;
	
	my @nodelist = $xml->getElementsByTagName('product');

	my @result;
	
	foreach my $node (@nodelist) {
		my $vendor = get_single($node, 'vendor', 1);
		my $name = get_single($node, 'name', 1);
		my $id = get_single($node, 'id', 1);
		
		#my $inblock = get_single($node, 'inblock', 1);
		
		my $image = get_single($node, 'image_name', 0);
		
		my $description = get_description($node);
		
		push @result, {
			id => $id,
			name => $name,
			vendor => $vendor,
			image => $image,
			description_full => $description
		};
		
	}
	return \@result;
}

sub get_description {
	my $node = shift;
	
	my @items = $node->getElementsByTagName('descriptionitem');
	
	my $description = '';
	foreach my $item (@items){
		$description .= '<p class="name">';
		$description .= $item->getAttribute('name');
		$description .= ':</p><span class="value">';
		$description .= $item->textContent();
		$description .= '</span>';
	}
	
	return $description
	
}

sub get_single {
	my ($node, $name, $strict) = @_;
	my @list = $node->getElementsByTagName($name);
	if (@list != 1 && $strict){
		die "There should be ONE value";
	}
	my $val = '';
	if (@list > 0){
		$val = $list[0]->textContent();
	}
	return $val;
}

sub load_xml {
	my $file = shift;
	my $parser = XML::LibXML->new();
  my $doc = $parser->parse_file( $file );
	return $doc;
}

sub load_price {
	my $name = shift;
	open (PR, $name) or die "Cannot load $name";
	my @lines = <PR>;
	close PR;
	my %price;
	foreach my $line(@lines){
		if ($line=~/^\d+;(\d+);[^;]+;[^;]+;(\d+);\d+/){
			$price{int($1)} = $2;
		}
	}
	return \%price;
}

sub load_price_2 {
	my $name = shift;
	open (PR, $name) or die "Cannot load $name";
	my @lines = <PR>;
	close PR;
	my %price;
	foreach my $line(@lines){
		if ($line=~/^(\d+);(\d+)$/){
			$price{int($1)} = $2;
		} else {
			#print "Skipping $line\n";
		}
	}
	return \%price;
}
