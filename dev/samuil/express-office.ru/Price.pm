package Price;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/prices',
	  tablename => 'Price',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Product_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Product',
  	ForeignKey => 'ID',
  });

  $self->addColumn('Category_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Category',
  	ForeignKey => 'ID',
  });

  return $self;
}



1;
