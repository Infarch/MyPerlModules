package ProductPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/P_FILES/samuil/prosmebel.ru/data/product',
	  tablename => 'ProductPicture',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Local_Filename', {
  	Type => $ISoft::DB::TYPE_VARCHAR,
  	Length => 32,
  	NotNull => 1
  });

  return $self;
}

sub getNameToStore {
	my $self = shift;
	return $self->get("Local_Filename");
}


1;
