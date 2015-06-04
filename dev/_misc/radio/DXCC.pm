package DXCC;

use strict;
use warnings;

our %STRICTS = (
	'4U1V' => 'Austria'

);

sub newFromFile {
	my $check = shift;
	my $class = ref($check) || $check;
	my $file = shift;
	my %data;
	my $self = bless \%data, $class;
	$self->_loadFile($file);
	return $self;
}

sub _loadFile {
	my ($self, $file) = @_;
	
	my %registry;
	
	open SRC, $file or die "Cannot open $file";
	
	my $country_name;
	my $waz;
	my $itu;
	my $continent;
	my $country_pfx;
	foreach my $line (<SRC>){
		$line =~ s/\s+$//;
		# try to parse the string as a header
		my @parts = split /:\s*/, $line;
		if(@parts == 8){
			# this is a header
			$country_name = $parts[0];
			$waz = $parts[1];
			$itu = $parts[2];
			$continent = $parts[3];
			$country_pfx = $parts[7];
		} else {
			# data block
			
			$line =~ s/#\s*(.+?): //;
			#my $c1 = $1;
			$line =~ s/^\s+//;
			
			my @calls = split /[,;]/, $line;
			#push @calls, $c1 if $c1;
			
			foreach my $call (@calls){

				# skip empty entries
				next unless $call;
				
				my %callinfo = (
					cn => $country_name,
					waz => $waz,
					itu => $itu,
					cnt => $continent,
					cp => $country_pfx
				);
				if($call=~s/\((\d+)\)//){
					$callinfo{waz} = $1;
				}
				if($call=~s/\[(\d+)\]//){
					$callinfo{itu} = $1;
				}
				
				if(exists $registry{$call}){
					print "Already exists $country_name : $call\n";
				}
				
				if (!exists $STRICTS{$call} || $STRICTS{$call} eq $country_name){
					$registry{$call} = \%callinfo;
				}
				
			}
			
		}
	}
	close SRC;
	
	$self->{registry} = \%registry;
}

sub searchCall {
	my($self, $call) = @_;
	$call =~ s/\/(QRPP|QRP|FF|P|M|MM|AM|A)$//;
	if($call =~ /(.+)\/(\d)$/){
		$call = $1;
		my $digit = $2;
		$call =~ s/(.+)\d([^\d]*)/$1$digit$2/;
	}
	elsif($call =~ /(.+)\/(.+)/){
		$call = "$2/$1" if length $2 < length $1;
	}
	# search the call in the internal registry
	while (my $l = length $call){
		if(exists $self->{registry}->{$call}){
			return $self->{registry}->{$call};
		}else{
			substr($call, $l-1) = '';
		}
	}
	return undef;
}

1;
