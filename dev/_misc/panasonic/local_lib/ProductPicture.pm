package ProductPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/p_files/panasonic/files/productpictures',
	  tablename => 'ProductPicture',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  return $self;
}



1;
