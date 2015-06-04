package ISoft::ParseEngine::Member::File::ProductPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/productpictures',
	  tablename => 'ProductPicture',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Product_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Product',
  	ForeignKey => 'ID',
  	NotNull => 1
  });

  return $self;
}



1;
