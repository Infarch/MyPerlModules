use strict;
use warnings;


use lib ("/work/perl_lib", "local_lib");


use ISoft::Conf;
use ISoft::DB;
use ISoft::DBHelper;

use Category;
use Product;

our %byProductCode; # ilc-000000 => webassyst id
our %prodCache; # url => ilc-000000
our @collector; # values to be inserted

our $script_dir = $constants{DestinationFiles}{SCRIPT_DIR};

our $dbh = get_dbh();
open MU, '>missedurls.txt';

start();

close MU;
release_dbh($dbh);

exit;

#####################################################################

sub start {
	my $prodlist = get_products($dbh);
	
	print scalar @$prodlist, " products to be processed\n";

	# build a hash containing the products
	foreach my $prod (@$prodlist){
		my $ext_id = $prod->{ID};
		my $int_id = $prod->{Code};
		$byProductCode{$int_id} = $ext_id;
	}
	
	# process products (using internal ids)
	foreach my $id (keys %byProductCode){
		print $id, "\n";
		process_product($id);
	}
	
	my $cnt = 1;
	while (@collector > 0){
		
		my @xlist;
		foreach(1..5000){
			push @xlist, shift @collector;
			last if @collector==0;
		}

		# save file
		open XX, ">$script_dir/connections_$cnt.sql";
		print XX "INSERT INTO `SC_related_items` (`Owner`, `productID`) VALUES\n";
		print XX join ",\n", @xlist;
		close XX;

		$cnt++;		
	}
	
	
}

sub process_product {
	my ($int_id) = @_;
	
	# get connection links
	my $prod = Product->new;
	$prod->set('InternalID', $int_id);
	$prod->markDone;
	unless($prod->checkExistence($dbh)){
		print "$int_id not found\n";
		return;
	}
	
	my @links = split ',', $prod->get('ProductLine');
	return if @links == 0;
	
	#print "Product line: @links\n";
	
	my $self_url = $prod->get('URL');
	
	# add to cache
	$prodCache{$self_url} = $int_id;
	
	my $ext_owner_id = $byProductCode{$int_id};
	
	foreach my $url (@links){
		
		# this url's query params are mixed so we have to re-arrange them
		if($url=~/fabrika=(\d+)&category=(\d+)&product=(\d+)/){
			$url = "http://www.interno-luce.ru/index.php?product=$3&sortbyfab&category=$2&fabrika=$1";
		}else{
			die "format error:\n$url\n\n";
		}
		
		next if $url eq $self_url; # skip self
		
		my $item_id = get_cached($url);
		unless(defined $item_id){
			print MU $url, "\n";
			next;
		}
		
		my $ext_item_id = $byProductCode{$item_id};
		unless(defined $ext_item_id){
			print "\nNO EXTERNAL ITEM $item_id\n$url\n";
			next;
		}
		
		my $str = "($ext_owner_id,$ext_item_id)";
		push @collector, $str;
		
	}
	
}

sub get_cached {
	my $url = shift;
	
	return $prodCache{$url} if exists $prodCache{$url};
	
	#print "Fetch...\n";
	
	my $prod = Product->new;
	$prod->set('URL', $url);
	return undef unless $prod->checkExistence($dbh);
	
	$prodCache{$url} = $prod->get('InternalID');
	
	return $prodCache{$url};
}

sub get_products {
	my $dbh = shift;
	
	my $sql = "select productID as ID, product_code as Code from sc_products where product_code like 'ilc-%'";
	my $rows = ISoft::DB::do_query($dbh, sql=>$sql);
	
	return $rows;
	
}
