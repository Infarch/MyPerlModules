package OptionValue;

use strict;
use warnings;


# base class
use base qw(ISoft::DB ISoft::ClassExtender);



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'OptionValue',
	  @_ # init
  );
  
  $self{Columns} = {
  	ID         => { Type => $ISoft::DB::TYPE_INT,     NotNull => 1, PrimaryKey => 1 },
  	Option_ID  => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Option' , ForeignKey => 'ID' },
  	Product_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product' , ForeignKey => 'ID' },
  	Value      => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 200 },
  };
  
  my $self = bless(\%self, $class);
  
  return $self;
}

sub prepareEnvironment {
	my ($self, $dbh) = @_;
	my $sql = $self->buildTableSql();
	ISoft::DB::do_query($dbh, sql=>$sql);
}



1;
