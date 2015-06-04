use strict;
use warnings;

use utf8;


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::DB;

use Category;
use Product;
use Property;
use ExportUtils;

my %names;
my %all;
my %fails;

our $dbh = get_dbh();

load_names();
process_features();

release_dbh($dbh);

exit;

sub process_features {
	
	# in order to avoid huge amounts of data, let's read features by product
	
	my @plist = ISoft::DB::do_query($dbh, sql=>"select `ID` from `Product` where `Status`=3");
	
	print scalar @plist, " products\n";
	
	foreach (@plist){
		my $pid = $_->{ID};
		print $pid, "\n";
		
		my @flist = ISoft::DB::do_query($dbh, sql=>"select `Name` from `Property` where `Product_ID`=$pid");
		foreach(@flist){
			my $name = $_->{Name};
			$fails{$name} = 1 unless exists $names{$name};
			$all{$name} = 1;
		}
		
	}
	
	print "\nRESULTS:\n\n";
	print "$_\n" foreach keys %fails;
	
	open XX, '>fields.txt';
	print XX "$_\n" foreach sort keys %all;
	close XX;
	
}

sub load_names {
	# read contents of `names`
	
	my @rows = ISoft::DB::do_query($dbh, sql=>"select * from `names`");
	print scalar @rows, " names\n";
	$names{$_->{name}} = 1 foreach @rows;
}