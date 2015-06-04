package Translit;

use strict;
use warnings;
use utf8;

use Encode;

our %RU_EN = (
	а => 'a',
	б => 'b',
	в => 'v',
	г => 'g',
	д => 'd',
	е => 'e',
	ё => 'e',
	ж => 'j',
	з => 'z',
	и => 'i',
	й => 'j',
	к => 'k',
	л => 'l',
	м => 'm',
	н => 'n',
	о => 'o',
	п => 'p',
	р => 'r',
	с => 's',
	т => 't',
	у => 'u',
	ф => 'f',
	х => 'h',
	ц => 'c',
	ч => 'ch',
	ш => 'sh',
	щ => 'sh',
	ъ => '',
	ы => 'y',
	ь => '',
	э => 'e',
	ю => 'ju',
	я => 'ja',
);

sub convert {
	my $input = shift;
	
	my @chars = split '', lc $input;
	my $output = '';
	
	foreach my $char (@chars) {
		$output .= exists $RU_EN{$char} ? $RU_EN{$char} : $char;
	}
	
	return $output;
}


1;
