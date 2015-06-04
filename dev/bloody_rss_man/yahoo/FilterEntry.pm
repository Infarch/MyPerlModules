package FilterEntry;

use strict;
use warnings;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $raw = shift;
  my $normal = normalize($raw);
  
  my $justdomain = $normal !~ /\//;
  
  my $temp = $normal;
 	$temp =~ s/\/.*//;
	my @parts = split '\.', $temp;

  my %self  = (
  	raw => $raw,
  	normal => $normal,
  	parts => \@parts,
  	justdomain => $justdomain,
  );
  
  return bless(\%self, $class);
}

sub justDomain {
	my $self = shift;
	return $self->{justdomain};
}

sub domainLevel {
	my $self = shift;
	return scalar @{ $self->{parts} };
}

sub getRaw {
	my $self = shift;
	return $self->{raw};
}

sub getDomain {
	my ($self, $level) = @_;
	
	my @parts = @{ $self->{parts} };
	if($level){
		my $len = @parts;
		@parts = @parts[$len-$level .. $len-1];
	}
	
	return join '.', @parts;
	
}

sub normalize {
	my $url = shift;
	$url =~ s/^http(s|):\/\/(www\.|)//i;
	$url =~ s/[?\/#]$//;
	return $url;
}









1;
