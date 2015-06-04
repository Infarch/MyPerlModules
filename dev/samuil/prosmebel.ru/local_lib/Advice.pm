package Advice;

use strict;
use warnings;


use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Advice',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID                => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Product_ID        => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	AdvicedProduct_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	Name              => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 500, NotNull => 1, Unique => 1 },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

1;
