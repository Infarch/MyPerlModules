use strict;
use warnings;



my @words;
load_lines('words.txt', \@words);

for (my $i=0; $i<@words; $i++){

	$words[$i] = ucfirst $words[$i];
	
}

save_lines('words.txt', \@words);

print "Done\n";
exit;


sub load_lines {
	my ($file, $list_ref) = @_;
	
	return 0 unless open SRC, '<:encoding(UTF-8)', $file;
	while (<SRC>){
		chomp;
		push @$list_ref, $_;
	}
	close SRC;
	return 1;
}

sub save_lines {
	my ($file, $list_ref, $append) = @_;
	
	my $operator = $append ? '>>' : '>';
	
	open DEST, $operator.':encoding(UTF-8)', $file or die "Cannot open file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}



