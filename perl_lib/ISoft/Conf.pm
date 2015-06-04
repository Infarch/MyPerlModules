package ISoft::Conf;

use strict;
use warnings;

use FindBin;

use base qw(Exporter);
use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );
our %constants;

BEGIN {
	# init module
	my $inifile = $FindBin::Bin . "/conf.ini";
	my $trim = sub {
		my $str = shift;
		$str =~ s/^\s+//;
		$str =~ s/\s+$//;
		return $str;
	};
	my $section = '_default_';
	open (INI, $inifile) or die "Can not open ini file $inifile";
	while (<INI>){
		chomp;
		my $line = $trim->($_);
		if ( $line =~ /^\s*#/ ) {
			# comment
		} elsif ($line =~ /^\s*\[(.+?)\]$/) {
			$section = $1;
		} elsif ( $line =~ /^([^=]+)=([^=]*)$/ ) {
			my $k = $1;
			my $v = $2;
			$k = $trim->($k);
			$v = $trim->($v);
			$constants{$section}{$k} = $v;
		}
	}
	close INI;
	@EXPORT = qw( %constants );
}
















1;
