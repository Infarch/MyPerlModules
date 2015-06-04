package SimpleConfig;

use strict;

use base qw(Exporter);
use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );

our %constants;

sub trim {
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}


BEGIN {
	# init module
	my $inifile = "conf.ini";
	my $section = '_default_';
	my $type = 'hash';
	open (INI, $inifile) or die "Can not open ini file $inifile";
	while (<INI>){
		chomp;
		my $line = trim($_);
		if ( $line =~ /^#/ ) {
			# comment
		} elsif ($line =~ /^\[(.+?)\]$/) {
			#$section = $1;
			my @parts = split '::', $1;
			$section = shift @parts;
			if( my $newtype = shift @parts ){
				$type = lc $newtype;
			} else {
				$type = 'hash';
			}
			if($type eq 'hash'){
				$constants{$section} = {};
			} elsif($type eq 'list'){
				$constants{$section} = [];
			} else {
				die "Wrong type $type";
			}
		} elsif ( $type eq 'hash' && $line =~ /^([^=]+)=([^=]*)$/ ) {
			# hash
			my $k = $1;
			my $v = $2;
			$k = trim($k);
			$v = trim($v);
			
			if (exists $constants{$section}{$k}){
				if(ref $constants{$section}{$k}){
					push @{$constants{$section}{$k}}, $v;
				} else {
					my $old = $constants{$section}{$k};
					$constants{$section}{$k} = [$old, $v];
				}
				
			} else {
				$constants{$section}{$k} = $v;
			}
		} elsif ($type eq 'list' && $line =~/\S/){
			# list
			push @{ $constants{$section} }, $line;
		}
	}
	close INI;
	
	@EXPORT = qw( %constants );
}
















1;
