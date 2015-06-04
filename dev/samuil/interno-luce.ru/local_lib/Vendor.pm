package Vendor;

use strict;
use warnings;

use utf8;

use Error ':try';

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	tablename => 'Vendor'
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  $self->addColumn('Description', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });
	
  $self->addColumn('PageTitle', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });

  $self->addColumn('PageMetakeywords', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });

  $self->addColumn('PageMetaDescription', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });


  return $self;
}


1;
