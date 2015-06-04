use strict;
use warnings;

use utf8;

use lib ("/work/perl_lib", "local_lib");

use File::Path;

use ISoft::Conf;
use ISoft::DB;
use ISoft::DBHelper;

#use Category;
use Product;
#use Property;
use Utils;

our %catCache; # id => name
our %tagCache; # tagName => tagId

our @collector; # values to be inserted
our @newtags; # new tags to be created;

my $script_dir = 'z:/P_FILES/samuil/prosmebel.ru/output/sql';

unless (-e $script_dir && -d $script_dir){
	mkpath($script_dir);
}

our @tagged_properties = ( "Production" );

our $dbh = get_dbh();

start();

$dbh->commit();

exit;

#####################################################################

sub start {
	
	# cache tags
	cache_tags();
	
	my $prodlist = get_products();
	
	print scalar @$prodlist, " products to be processed\n";

	# generate tags for each product
	process_product($_) foreach @$prodlist;
	
	open XX, ">$script_dir/tags.sql";
	
	foreach (@newtags){
		print XX "$_\n";
	}
	
	print XX "\n\n";
	
	while (@collector > 0){
		
		my @xlist;
		foreach(1..500){
			push @xlist, shift @collector;
			last if @collector==0;
		}

		# save file
		print XX "INSERT INTO `SC_tagged_objects` (`tag_id`, `object_id`, `object_type`, `language_id`) VALUES\n";
		print XX join ",\n", @xlist;
		print XX ";\n\n";
		
	}
	
	close XX;
	
}

sub get_tag_id {
	my ($tagname) = @_;
	if(exists $tagCache{$tagname}){
		return $tagCache{$tagname};
	}
	# new tag
	my $id = Utils::insert_tag($dbh, $tagname, \@newtags);
	$tagCache{$tagname} = $id;
	return $id;
}

sub process_product {
	my $row = shift;
	
	#check whether the product exists in local database using it's code
	my $id = $row->{ID};
	my $code = $row->{Code};
	my $prod = Product->new;
	
	# extract the product id from its code
	if($code =~ /^PM-0*(\d+)/){
		$prod->set('ID', $1);
	}else{
		return if $code =~ /^PM-UPH-/;
		die "Bad code '$code'";
	}

	$prod->markDone();
	
	$prod->select($dbh);
	
	my $prod_id = $prod->ID;
	# fetch the parent category, either from cache or DB
#	my $cat_id = $prod->get('Category_ID');
#	my $cat_name;
#	unless (exists $catCache{$cat_id}){
#		my $cat = Category->new;
#		$cat->set('ID', $cat_id);
#		$cat->select($dbh);
#		$cat_name = $cat->Name;
#		$cat_name =~ s/\r|\n|\t/ /g;
#		$cat_name =~ s/^\s+//;
#		$cat_name =~ s/\s+$//;
#		$catCache{$cat_id} = $cat_name;
#	} else {
#		$cat_name = $catCache{$cat_id};
#	}
#	
#	# look for a tag having the same name
#	my $tag_id = get_tag_id($cat_name);
#	push @collector, "($tag_id,$id,'product',1)";
	
	# make tags for several product properties
#	foreach my $prop (@tagged_properties){
#		my $property_obj = Property->new;
#		$property_obj->set('Product_ID', $prod_id);
#		$property_obj->set('Name', $prop);
#		if($property_obj->checkExistence($dbh)){
#			my $x = $property_obj->get('Value');
#			if(defined $x){
#				if($prop eq 'Материалы'){
#					$x =~ s/покрытия\s+//g;
#				}
#				my $tid = get_tag_id($x);
#				push @collector, "($tid,$id,'product',1)";
#			}
#		}
#	}
	
	# 'Production' is the single tag
	if(my $production = $prod->get("Production")){
		my $tid = get_tag_id($production);
		push @collector, "($tid,$id,'product',1)";
	}
	
}

sub cache_tags {
	my $sql = "select * from SC_tags";
	my $rows = ISoft::DB::do_query($dbh, sql=>$sql);
	foreach my $row(@$rows){
		$tagCache{$row->{name}} = $row->{id};
	}
}

sub get_products {
	my $sql = "select productID as ID, product_code as Code from sc_products where product_code like 'PM-%'";
	my $rows = ISoft::DB::do_query($dbh, sql=>$sql);
	return $rows;
}
