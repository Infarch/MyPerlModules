package CategoryPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/categorypictures',
	  tablename => 'CategoryPicture',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Category_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Category',
  	ForeignKey => 'ID',
  	NotNull => 1
  });

  return $self;
}



1;
