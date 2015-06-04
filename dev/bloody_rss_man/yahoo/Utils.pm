package Utils;


use strict;
use warnings;









sub load_lines {
	my ($file, $list_ref) = @_;
	open SRC, $file or die "Cannot open $file: $!";
	while (<SRC>){
		chomp;
		push @$list_ref, $_ if $_;
	}
	close SRC;
}

sub save_lines {
	my ($file, $list_ref, $append) = @_;
	my $operator = $append ? '>>' : '>';
	open DEST, "$operator$file" or die "Cannot open $file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}
















1;
