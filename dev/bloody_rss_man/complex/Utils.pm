package Utils;

use strict;
use warnings;
use base qw(Exporter);

# This package provides auxiliary functions for all scripts within the project


our @EXPORT;

BEGIN {
	
	my @general = qw( load_lines save_lines );
	my @bll = qw ( check_state set_state cleanup_state );
	
	@EXPORT = (@general, @bll);
	
}

# business logic functions

sub get_state_file_name {
	return "$_[0].state";
}

sub check_state {
	my $file = get_state_file_name($_[0]);
	return ((-e $file) && (-f $file)) || 0 ;
}

sub set_state {
	my $name = shift;
	my $file = get_state_file_name($name);
	open (XX, ">$file") or die "Cannot create state file $file: $!\n";
	print XX $name;
	close XX;
}

sub cleanup_state {
	my $name = shift;
	my $file = get_state_file_name($name);
	if(-e $file && -f $file){
		unlink ($file) or die "Cannot remove state file $file: $!\n";
	}
}




# file management functions

sub save_lines {
	my ($file, $lines_ref, %params) = @_;
	my $operator = $params{append} ? '>>' : '>';
	open (XX, $operator, $file) or die "Cannot open $file: $!\n";
	foreach (@$lines_ref){
		print XX "$_\n";
	}
	close XX;
}

sub load_lines {
	my ($file, %params) = @_;
	if (open (XX, $file)){
		my @lines;
		my %registry;
		foreach my $line (<XX>){
			chomp $line;
			if ($line!~/\S/ && $params{not_empty}){
				next;
			}
			if ($params{unique}){
				if (exists $registry{$line}){
					next;
				} else {
					$registry{$line} = 1;
				}
			}
			push @lines, $line;
		}
		close XX;
		return @lines;
	} else {
		if($params{not_strict}){
			return ();
		} else {
			die "Cannot open $file: $!\n";
		}
	}
}

















1;
