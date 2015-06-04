package ProductDescriptionPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/descriptionpictures',
	  tablename => 'ProductDescriptionPicture',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Product_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Product',
  	ForeignKey => 'ID',
  	NotNull => 1
  });

  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  return $self;
}



1;
