use strict;
use warnings;

use WWW::Mechanize;


my $mech = WWW::Mechanize->new(autocheck=>0);

my $old = '';
my $count = 0;

while (1) {
	
	my $old_code = 0;
	my $tm = time;
	my @lines;
	my $ok = $mech->get("http://f1ua.myvnc.com/live-f1.scr?time=$tm");
	if ( $ok && $mech->status() =~ /^200/ ) {
		
		my $content = $mech->content();
		
		my $out = '';
		my $raw_out = '';
		my $col = 0;
		for (my $i=12; $i<length $content; $i+=2){
			
			my $color_code = ord( substr $content, $i+1, 1 );
			if($color_code !=$old_code){
				$old_code = $color_code;
				my $hex = sprintf("%02X", $color_code);
				$out .= '#' . $hex;
			}
			
			$out .= substr $content, $i, 1;
			
			if ($col++ == 79){
				$out =~ s/^\s+//;
				push @lines, $out;
				$raw_out .= $out;
				$out = '';
				$col = 0;
			} 
		}
		
		if ($out){
			$out =~ s/^\s+//;
			$raw_out .= $out;
			push @lines, $out;
		}
		
		
		
		my $ltm = localtime($tm);
		
		if ($old ne $raw_out){
			$old = $raw_out;
			
			open RES, '>>result.txt';
			print RES $ltm, "\n\n";
			print RES join "\n", @lines;
			print RES "\n---------------------------------------------------------------\n\n";
			close RES;
		}
		
		if ($count++ == 180){
			$count = 0;
			print "$ltm : I'm still working :)\n";
		}
		
		
	} else {
		print "Request failed\n";
	}
	
	
	sleep 1;
}

	

