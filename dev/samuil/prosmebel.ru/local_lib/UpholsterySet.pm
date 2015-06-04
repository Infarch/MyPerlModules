package UpholsterySet;

use strict;
use warnings;


use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'UpholsterySet',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID   => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Name => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 250, NotNull => 1 },
  	URL  => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 500, NotNull => 1 },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}



1;
