package Manual;

use strict;
use warnings;

use lib ("/work/perl_lib");

# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/P_FILES/panasonic_manuals/manuals',
	  tablename => 'Manual',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Category_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Category',
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
