package ISoft::ParseEngine::Member::File::Photo;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/photos',
	  tablename => 'Photo',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Album_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Album',
  	ForeignKey => 'ID',
  	NotNull => 1
  });

  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  $self->addColumn('Description', {
		Type => $ISoft::DB::TYPE_TEXT
  });

  return $self;
}



1;
