package ProductPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/P_FILES/e96/productpictures',
  );
  
  my $self = $class->SUPER::new(%params, @_);

  return $self;
}



1;
