package ProductTable;

use strict;
use warnings;


use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'ProductTable',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID         => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Product_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	Price      => { Type => $ISoft::DB::TYPE_INT, Default => 0 },
  	Name       => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 250 },
  	Art_No     => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 128, NotNull => 1, Default => '' },
  	Size       => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 128, NotNull => 1, Default => '' },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}


1;
