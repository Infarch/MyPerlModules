package ProductUpholstery;

use strict;
use warnings;


use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'ProductUpholstery',
	  @_
  );
  
  $params{Columns} = {
  	ID            => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Upholstery_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Upholstery', ForeignKey => 'ID' },
  	Product_ID    => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

1;
