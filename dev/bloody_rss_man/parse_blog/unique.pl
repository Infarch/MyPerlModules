use strict;
use warnings;

use List::Util 'shuffle';

my %registry;

my @words;
load_lines('words.txt', \@words);

my @result;

foreach my $word (@words){

	next if exists $registry{$word};
	$registry{$word} = 1;
	push @result, $word;
	
}

if( $ARGV[0] && $ARGV[0] eq 'r'){
	# do shufle
	print "Shullle was requested\n";
	@result = shuffle @result;
}

save_lines('words.txt', \@result);

print "Done\n\n";

if (scalar @result < scalar @words){
	print scalar @words - scalar @result, "\n";
}

print scalar @result, "\n";

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



