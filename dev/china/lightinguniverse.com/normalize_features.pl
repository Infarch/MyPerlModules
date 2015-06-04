use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ISoft::DB;
use ISoft::DBHelper;

my $registry = {};


my $dbh = get_dbh();

# get products ids
my $prods = ISoft::DB::do_query($dbh, sql=>"select product_id from cscart_products");

# get ALL features ids
my $fids = ISoft::DB::do_query($dbh, sql=>"select feature_id from cscart_product_features");
my %all = map { $_->{feature_id}=>1} @$fids;

my $l=1000;
foreach my $product_id (map {$_->{product_id}} @$prods){
	
	print "$product_id\n";
	
	# get the product's features
	my $features_variants = ISoft::DB::do_query($dbh, sql=>"select product_id , feature_id from cscart_product_features_values where product_id=$product_id");
	my %features = map { $_->{feature_id} => 1 } @$features_variants;
	
	# get the product's categories
	my $categories = ISoft::DB::do_query($dbh, sql=>"select category_id from cscart_products_categories where product_id=$product_id");

#	print "$product_id has ";
#	print scalar(keys %features), " features and presents in ";
#	print scalar @$categories, " categories\n";
	
	foreach my $fid ( keys %features ){
		$registry->{$fid} = {} unless exists $registry->{$fid};
		foreach my $cid ( map { $_->{category_id} } @$categories ){
			$registry->{$fid}->{$cid} = 1;
		}
	}
	
	#last unless $l--;
	
}

open X1, '>fetures_corr.sql';

while( my($fid, $cats) = each %$registry){
	if(keys(%$cats)>0){
		delete $all{$fid};
		my $c = join ',', keys %$cats;
		print X1 "update `cscart_product_features` set categories_path='$c' where `feature_id`=$fid;\n";
	}
}

close X1;

open X2, '>unused_features.txt';
print X2 join( ',', keys %all);
close X2;




release_dbh($dbh);

