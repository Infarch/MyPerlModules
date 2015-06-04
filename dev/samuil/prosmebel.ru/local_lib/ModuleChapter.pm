package ModuleChapter;

use strict;
use warnings;

use Module;

use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'ModuleChapter',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID         => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Product_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	Name       => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 256 },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

sub getModules {
	my($self, $dbh) = @_;
	my $m = Module->new;
	$m->set("Chapter_ID", $self->ID);
	return $m->listSelect($dbh);
}


1;
