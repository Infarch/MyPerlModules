use strict;
use warnings;


# parse arguments

my $filename;
my $lines;

if (@ARGV == 0 || @ARGV > 2){
	die "Error - bad arguments";
} elsif (@ARGV == 1) {
	$lines = shift @ARGV;
	$filename = 'fresh.txt';
} else {
	($filename, $lines) = @ARGV;
}

my ($fname, $fext) = $filename =~ /(.*)(\..*)/;
unless ($fext){
	$fname = $filename;
	$fext = '';
}

my @file;
load_lines($filename, \@file);

my $total = @file;

my $count = 0;
my @part;
my $pn = 1;
my $pc = 0;
foreach my $line (@file){
	push @part, $line;
	if(++$count == $lines){
		$pc += do_save($fname, $fext, $pn++, \@part);
		@part = ();
		$count = 0;
	}
}
$pc += do_save($fname, $fext, $pn++, \@part);


print "Total: $total\nParts: $pc\n";



exit;

sub do_save {
	my ($org_name, $org_ext, $partnumber, $listref) = @_;
	return 0 if @$listref==0;
	
	my $new_name = "${org_name}_part_$partnumber$org_ext";
	save_lines($new_name, $listref);
	return 1;
}

sub load_lines {
	my ($file, $list_ref) = @_;
	open SRC, '<:encoding(UTF-8)', $file or die "Cannot open file $file: $!";
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
	open DEST, $operator.':encoding(UTF-8)', $file or die "Cannot open file $file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}
