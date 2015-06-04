use strict;
use warnings;

use SimpleConfig;




srand();

my @fresh;
load_lines($constants{General}{Fresh}, \@fresh);

my @words;
load_lines($constants{General}{Words}, \@words);

print scalar @fresh, " strings in fresh\n";
print scalar @words, " words\n";

if (@words < @fresh){
	print "No enough words, exit\n";
	exit;
}

my @used_words;

my $count = 0;
while (@words > 0 && $count < @fresh){
	
	my $word = shift @words;
	$fresh[$count] = do_insert($fresh[$count], $word);
	
	push @used_words, $word;
	
	$count++;
}

save_lines($constants{General}{Fresh}, \@fresh);
save_lines($constants{General}{Words}, \@words);
save_lines($constants{General}{UsedWords}, \@used_words);

print "Done\n";
exit;




sub do_insert {
	my ($string, $word) = @_;
	
	$word = '['.$word.']';
	
	my @poslist;
	
	while ( $string =~ /[.!?]/g ){
		push @poslist, (pos $string)-1;
	}
	
	if(@poslist>0){
		
		my $position = $poslist[int(rand(@poslist))];
		my $current_char = substr $string, $position, 1;
		substr ($string, $position, 1) = "$current_char $word.";
				
		return $string;
		
	} else {
		return "$string. $word.";
	}
	
}

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



