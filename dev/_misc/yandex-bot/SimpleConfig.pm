package SimpleConfig;

use strict;

use base qw(Exporter);
use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );

our %constants;

BEGIN {
	# init module
	my $inifile = "conf.ini";
	my $trim = sub {
		my $str = shift;
		$str =~ s/^\s+//;
		$str =~ s/\s+$//;
		return $str;
	};
	my $section = '_default_';
	my $is_list = 0;
	open (INI, $inifile) or die "Can not open ini file $inifile";
	while (<INI>){
		chomp;
		my $line = $trim->($_);
		if ( $line =~ /^#/ ) {
			# comment
		} elsif ($line =~ /^\[(.+?)\]$/) {
			# section
			my $sname = $1;
			# check modifiers
			my @parts = split ':', $sname;
			$section = $parts[0];
			if (@parts==2 && $parts[1] eq 'list'){
				$is_list = 1;
				$constants{$section} = [];
			} else {
				$is_list = 0;
			}
		} elsif ( !$is_list && $line =~ /^([^=]+)=([^=]*)$/ ) {
			# hash value
			my $k = $1;
			my $v = $2;
			$k = $trim->($k);
			$v = $trim->($v);
			$constants{$section}{$k} = $v;
		} elsif ( $is_list && $line =~ /\S/ ) {
			push @{ $constants{$section} }, $trim->($line);
		}
	}
	close INI;
	
	@EXPORT = qw( %constants );
}
















1;
