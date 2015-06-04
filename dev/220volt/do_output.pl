use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use Encode qw/encode decode/;
use Digest::MD5 'md5_hex';

use ISoft::Conf;
use ISoft::DBHelper;
use Category;
use Product;
use Attribute;

my @collector;
my $limit = 0;

my $dbh = get_dbh();

cache();

get_data();
do_output();

release_dbh($dbh);

exit;

######################################

sub webassyst_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'Code', mapto=>'code'},
		{ title=>'Name', mapto=>'name'},
		{ title=>'Category', mapto=>'category'},
		{ title=>'Price', mapto=>'price'},
		{ title=>'Description', mapto=>'description'},
	);	

	my $sql = "select distinct(Name) from attribute";
	my @rows = ISoft::DB::do_query($dbh, sql=>$sql);
	foreach my $row(@rows){
		my $name = $row->{Name};
		push @all_columns_ru, {
			title=>$name, mapto=>md5_hex(encode("utf-8",$name))
		};
	}
	
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
	
	foreach my $dataitem (@collector){
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

sub do_output {
	
	my $result_ref = webassyst_provider();
	open (CSV, '>', "data.csv")
		or die "Cannot open file data.csv: $!";
		
	foreach my $line (@$result_ref){
		$line = encode("utf-8", $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	
	close CSV;

}

sub process_product {
	my($prod_obj, $path) = @_;
	my $pid = $prod_obj->ID;
	print "Product $pid\n";
	
	my %data;
	$data{category} = $path;
	$data{name} = $prod_obj->Name;
	$data{code} = $prod_obj->get('InternalID');
	$data{price} = $prod_obj->get('Price');
	$data{description} = $prod_obj->get('Description');
	
	my $attr_obj = Attribute->new;
	$attr_obj->set("Product_ID", $pid);
	my @alist = $attr_obj->listSelect($dbh);
	foreach my $attr (@alist){
		my $name = $attr->Name;
		$data{ md5_hex(encode("utf-8",$name)) } = $attr->get("Value");
	}
	
	
	push @collector, \%data;
}

sub process_category {
	my ($cat_obj, $path) = @_;
	my $cid = $cat_obj->ID;
	print "Category $cid\n";
	
	my $cname = $cat_obj->Name;
	$path .= "/" if $path;
	$path .= $cname;
	
	my $child_obj = Category->new;
	$child_obj->set("Category_ID", $cid);
	$child_obj->set("Status", 3);
	my @children = $child_obj->listSelect($dbh);
	process_category($_, $path) foreach @children;
	
	my $prod_obj = Product->new;
	$prod_obj->set("Category_ID", $cid);
	$prod_obj->set("Status", 3);
	$prod_obj->maxReturn($limit) if $limit;
	my @prodlist = $prod_obj->listSelect($dbh);
	process_product($_, $path) foreach @prodlist;
}

sub get_data {
	my $obj = Category->new;
	$obj->set("Level", 1);
	$obj->set("Status", 3);
	my @list = $obj->listSelect($dbh);
	process_category($_, "") foreach @list;
}

sub cache {
#	# read categories
#	my $cat_obj = Category->new;
#	$cat_obj->set("Status", 3);
#	my @clist = $cat_obj->listSelect($dbh);
#	
#	print scalar @clist, " categories\n";
#	
#	%categories = map { $_->ID => $_ } @clist;
	
#	my $sql = "select distinct(Name) from attribute";
#	my @rows = ISoft::DB::do_query($dbh, sql=>$sql);
#	
#	print scalar @rows, " attributes\n";
#	
#	foreach my $row(@rows){
#		my $name = $row->{Name};
#		print md5_hex(encode("utf-8",$name)), "\n";
#	}
}
