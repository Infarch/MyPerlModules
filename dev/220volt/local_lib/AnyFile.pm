package AnyFile;
#       ^^^^^^^
# rename the package and use for any type of file. of course some setup will be required - don't forget it!

use strict;
use warnings;

use lib ("/work/perl_lib");

# base class
use base qw(ISoft::ParseEngine::Member::File::xxx);
#                                             ^^^
# what to implement?                    

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'files/anyfiles', # change this path!!!
	  tablename => 'AnyFile', # rename the table!!!
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

#  $self->addColumn('Category_ID', {
#  	Type => $ISoft::DB::TYPE_INT,
#  	ForeignTable => 'Category',
#  	ForeignKey => 'ID',
#  	NotNull => 1
#  });

#  $self->addColumn('Product_ID', {
#  	Type => $ISoft::DB::TYPE_INT,
#  	ForeignTable => 'Product',
#  	ForeignKey => 'ID',
#  	NotNull => 1
#  });

  return $self;
}



1;
