use strict;
use warnings;


# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;
use ISoft::DB;


test_names();


# ----------------------------


sub test_names {
	my $dbh = get_dbh();
	
	my @rows = ISoft::DB::do_query($dbh, sql=>"select `name` from `names`");
	my %ncache = map { $_->{name} => 1 } @rows;
	print "There are ", scalar keys %ncache, " unique names among ", scalar @rows, " items\n";
	
	my @props = ISoft::DB::do_query($dbh, sql=>"select `Name` from `Property`");
	print "There are ", scalar @props, " properties\n";
	
	my %fails;
	
	foreach my $prop (@props){
		
		my $name = $prop->{Name};
		$fails{$name} = 1 unless exists $ncache{$name};
		
	}
	
	print "Done\n";
	
	print "$_\n" foreach keys %fails;
	
	
	
	
	release_dbh($dbh);	
}
