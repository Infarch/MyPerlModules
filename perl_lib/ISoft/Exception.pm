package ISoft::Exception;

use base qw(Error::Simple);

use strict;
use warnings;

use Carp;


# !!!!!!!!!!!!!!!!
# Dont throw this class directly - meant for subclassing only

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %params  = (
	  @_ # init
  );

	# Standard parameters
	my $message = $params{message};
	my $id = $params{err_id} || time;
	
	# Call super constructor
	my $self = $class->SUPER::new($message, $id);

	# store params into object
	while ( my($key, $value) = each %params ){
		$self->{$key} = $value;
	}
	
	my $prev_carplevel = $Carp::CarpLevel;
	$Carp::CarpLevel = 1;
	$self->{trace} = Carp::longmess;
	$Carp::CarpLevel = $prev_carplevel;
	
  return $self;
}

sub message {
	return $_[0]->{message};
}

sub trace {
	return $_[0]->{trace};
}

sub longMessage {
	my $self = shift;
	return $self->{message}.":\t".$self->{trace};
}

1;