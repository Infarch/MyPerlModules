use strict;
use warnings;

my $source_name = 'file.txt';
my $dest_name = 'iplist.txt';



open (SRC, $source_name) or die "Cannot open $source_name";
my $str = '';
while (<SRC>){
	chomp;
	$str .= "$_ x"
}
close SRC;

open (DEST, ">$dest_name") or die "Cannot open $dest_name";
my %ip_registry;
while ( $str =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g ){
	my $ip = $1;
	unless ( exists $ip_registry{$ip} ){
		$ip_registry{$ip} = 1;
		print DEST "From sv $ip\n";
	}
} 
close DEST;

print "Done\n";

