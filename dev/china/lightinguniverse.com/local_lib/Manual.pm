package Manual;

use strict;
use warnings;

# base class
use base qw(ISoft::ParseEngine::Member::File);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'z:/P_FILES/lightinguniverse/manuals',
	  tablename => 'Manual',
	  namecolumn => 'Name',
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

sub getExceptionWeight {
	my($self, $exception) = @_;
	if(my $name = ref $exception){
		if($name eq 'ISoft::Exception::NetworkError'){
			return 10;
		}
	}
	return return $self->SUPER::getExceptionWeight($exception);
}


1;
