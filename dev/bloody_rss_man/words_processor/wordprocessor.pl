use strict;
use warnings;

use SimpleConfig;


# load words
my @lines;
load_lines($constants{General}{WordsFile}, \@lines) or die "Cannot open file";

# process
my @result;
foreach my $line (@lines){
	push @result, process_line($line);
}

# do output
save_lines($constants{General}{OutputFile}, \@result);

exit;

sub process_line {
	my ($line) = @_;
	
	my @words = split /\s+/, $line;
	
	my @wr;
	
	foreach my $word (@words){
		push @wr, process_word($word);
	}
	
	return join ' ', @wr;
}

sub process_word {
	my ($word) = @_;
	my $max = $constants{General}{MaxCharacters};
	if($max){
		if (length ($word) > $max){
			$word = substr $word, 0, $max;
		}
	}
	return $word;
}


sub load_lines {
	my ($file, $list_ref) = @_;
	
	return 0 unless open SRC, '<', $file;
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
	
	open DEST, $operator, $file or die "Cannot open file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}

