package ProductDescriptionPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductDescriptionPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/P_FILES/e96/descriptionpictures',
  );
  
  my $self = $class->SUPER::new(%params, @_);

  return $self;
}

sub getExceptionWeight {
	my($self, $exception) = @_;
	if(my $name = ref $exception){
		if($name eq 'ISoft::Exception::NetworkError'){
			return 20;
		}
	}
	return return $self->SUPER::getExceptionWeight($exception);
}


1;
