use strict;
use warnings;

use LWP::Simple 'getstore';

my @list;

# load list
open SRC, 'list.txt';
while (my $line = <SRC>){
	chomp $line;
	push @list, $line;
}
close SRC;


# prepare directories
if(!-e 'lib' && !-d 'lib'){
	mkdir 'lib' or die $!;
}
my %reg;
foreach my $line (@list){
	my ($cat, $name, $size) = split ' ', $line;
	next if exists $reg{$cat};
	if(!-e "lib/$cat" && !-d "lib/$cat"){
		mkdir "lib/$cat" or die $!;
	}
	$reg{$cat} = 1;
}

# do work
foreach my $line (@list){
	
	process_file($line);
	
}

exit;


sub process_file {
	my $line = shift;
	my ($cat, $name, $size) = split ' ', $line;
	my $path = "lib/$cat/$name";
	my $url = "http://book-download.pp.ua/lib/$cat/$name";
	if (-e $path){
		print "$name skipped\n";
		return;
	} 
	my $code = getstore($url, $path);
	if ($code == 200){
		print "$name stored\n";
	} else {
		report_error($code, $path);
	}
}

sub report_error {
	my ($code, $name) = @_;
	open RR, '>>report.txt';
	print RR "$code $name\n";
	close RR;
}
