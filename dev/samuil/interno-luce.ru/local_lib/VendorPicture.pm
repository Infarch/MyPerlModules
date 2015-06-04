package VendorPicture;

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
  	tablename => 'VendorPicture'
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Vendor_ID', {
		Type => $ISoft::DB::TYPE_INT,
		ForeignTable => 'Vendor',
  	ForeignKey => 'ID'
  });



  return $self;
}


1;
