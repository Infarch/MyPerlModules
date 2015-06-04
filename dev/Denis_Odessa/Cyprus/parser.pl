use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Error ':try';
use File::Copy;
use Image::Resize;
use XML::LibXML;


my $sql = "";

my $xmlstr = '';

open SRC, 'result.xml';
while (<SRC>){
	chomp;
	$xmlstr .= $_;
}
close SRC;

my $parser = XML::LibXML->new();
my $doc = $parser->parse_string($xmlstr);

my @categories = $doc->getElementsByTagName('category');

print scalar @categories, " categories\n";

foreach my $category (@categories){
	insert_category($category);
}


# create sql file
open SQL, '>data.sql';
print SQL $sql;
close SQL;


######################################################################################################################################

sub get_safe {
	my ($node, $name) = @_;
	my $value = $node->findvalue($name);
	
	$value =~ s/'/''/g; #'
	
	return $value;
}

sub insert_category {
	my ($node) = @_;
	
	my $category_name = $node->findvalue('name');
	my @properties = $node->getElementsByTagName('property');
	my $count = @properties;
	
	# make sql
	$sql .= "insert into SS_categories (name, parent, products_count, description, products_count_admin) values ('$category_name', 2, $count, '$category_name', $count);\n";
	
	my @sql_list;
	
	foreach my $property (@properties){
		push @sql_list, get_property_values($property);
	}
	
	$sql .= "insert into SS_products (categoryID, name, description, price, thumbnail, customers_rating,".
		" customer_votes, items_sold, big_picture, picture, enabled, brief_description) values\n";
	
	$sql .= join ",\n", @sql_list;
	$sql .= ";\n\n";
}

sub get_property_values {
	my ($node) = @_;
	
	my $brief_description = get_safe($node, 'description');
	my $thumbnail = get_safe($node, 'thumbnail');
	my $title = get_safe($node, 'title');
	
	my $description = '';
	my $price = 0;
	my $big_picture = 'null';

	# price
	my $value = get_safe($node, 'price');
	if ($value =~ /^([ \d]+) \$$/){
		my $xx = $1;
		$xx =~ s/ //g;
		$price = $xx;
	}
	
	my @dlist = $node->getElementsByTagName('details');
	if (@dlist == 1){
		my $dnode = $dlist[0];
		# description and features
		my $value = get_safe($dnode, 'description');
		if($value){
			$description .= $value;
		}
		$value = get_safe($dnode, 'features');
		if($value){
			if ($description){
				$description .= "<br/><br/>";
			}
			$description .= $value;
		}
		
		# big picture
		$value = get_safe($dnode, 'photo');
		if($value){
			$big_picture = $value;
		}
		
	}
	
	$description = $brief_description unless $description;
	
	# improve picture
	if ($big_picture ne 'null'){
		
		# make thumbnail
		try {
			my $resize = Image::Resize->new("photo/$big_picture");
			my ($width, $height) = $resize->gd()->getBounds();
			my $gd;
			if ( $width > 285 ) {
				$gd = $resize->resize(285, 285);
			} else {
				$gd = $resize->gd();
			}

			$thumbnail = "t_$big_picture";
			
			copy("photo/$big_picture", "images_export/$big_picture") or die "Can not copy $big_picture";
			
			$big_picture = "'$big_picture'";
			
			open DST, ">images_export/$thumbnail" || return 0;
			binmode DST;
			print DST $gd->jpeg();
			close DST;

			
		} otherwise {
			print "Error resizing $big_picture\n";
			$big_picture = 'null';
		};
		
		
	} else {
		# use existing thumbnail
		if ($thumbnail){
			copy("photo/$thumbnail", "images_export/$thumbnail") or die "Can not copy $thumbnail";
		}
	}
	
	return "(LAST_INSERT_ID(), '$title', '$description', $price, '$thumbnail', 0, 0, 0, $big_picture, '$thumbnail', 1, '$brief_description')";
	
}






