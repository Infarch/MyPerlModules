package AssemblyManual;


use strict;
use warnings;

use lib ("/work/perl_lib");

# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/assembly_manuals',
	  tablename => 'AssemblyManual'
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
