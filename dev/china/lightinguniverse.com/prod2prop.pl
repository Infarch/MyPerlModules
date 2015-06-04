use strict;
use warnings;

die 'done';

use lib ("/work/perl_lib", "local_lib");

use Product;
use Property;

use ISoft::DBHelper;

my $dbh = get_dbh();

print "Start\n";

my $prod = Product->new;
$prod->markDone();

my @columns = grep { /^Prop/ } keys %{$prod->{Columns}};

my @list = $prod->listSelect($dbh);

print "There are ", scalar @list, " products to be processed\n";



foreach $prod (@list){
	
	my $pid = $prod->ID;
	
	foreach my $colname (@columns){
		
		my $val = $prod->get($colname);
		next unless defined $val;
		
		my $pname = substr $colname, 4;

		my $prop = Property->new;
		$prop->set('Product_ID', $pid);
		$prop->set('Name', $pname);
		$prop->set('Value', $val);
		$prop->insert($dbh, 1);
		
	}
	
	print "$pid\n";
	
	
	
	
	
	
}


$dbh->commit();

