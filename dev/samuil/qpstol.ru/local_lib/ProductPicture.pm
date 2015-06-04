package ProductPicture;

use strict;
use warnings;


use constant TYPE_NORMAL => 1;
use constant TYPE_ASIS   => 2;
use constant TYPE_COLOR  => 3;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new(@_);

	# create additional columns

  $self->addColumn('Type', {
  	Type => $ISoft::DB::TYPE_TINYINT,
  	NotNull => 1,
  	Default => $self->TYPE_NORMAL
  });

  return $self;
}



1;
