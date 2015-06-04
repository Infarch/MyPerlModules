package Module;

use strict;
use warnings;

use ModuleColor;
use ModulePicture;

use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Module',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID         => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Chapter_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'ModuleChapter', ForeignKey => 'ID' },
  	Product_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	Price      => { Type => $ISoft::DB::TYPE_INT, Default => 0 },
  	Name       => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 250 },
  	Art_No     => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 128, NotNull => 1, Default => '' },
  	Size       => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 128, NotNull => 1, Default => '' },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

sub getModuleColors {
	my($self, $dbh) = @_;
	
	my $mc = ModuleColor->new();
	$mc->set("Module_ID", $self->ID);
	return $mc->listSelect($dbh);
}

sub getModulePicture {
	my($self, $dbh) = @_;
	my $mp_obj = ModulePicture->new;
	$mp_obj->set("Module_ID", $self->ID);
	$mp_obj->markDone();
	return $mp_obj->checkExistence($dbh) ? $mp_obj : undef;
}

1;
