package ExportUtils;

use strict;
use warnings;
use utf8;

# might contain some pre-defined names
our %property_names;

sub get_property_name {
	my $packed = shift;
	$property_names{$packed} = split_property_name($packed) unless exists $property_names{$packed};
	return $property_names{$packed};
}

sub split_property_name {
	my @chars = split '', shift;
	my $output = '';
	my $state = isUC($chars[0]);
	foreach my $c (@chars){
		my $s1 = isUC($c);
		if($s1 && !$state){
			$output .= " ";
		}
		$state = $s1;
		$output .= $c;
	}
	return $output;
}

sub isUC {
	my $a = shift;
	return $a eq uc $a ? 1 : 0;
}


1;
