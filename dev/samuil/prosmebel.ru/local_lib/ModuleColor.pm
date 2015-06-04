package ModuleColor;

use strict;
use warnings;


use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'ModuleColor',
	  namecolumn => 'Color',
	  @_
  );
  
  $params{Columns} = {
  	ID        => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Module_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Module', ForeignKey => 'ID' },
  	Color     => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 256, NotNull => 1 },
  	Code      => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 256, NotNull => 1, Default => '' },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}


1;
