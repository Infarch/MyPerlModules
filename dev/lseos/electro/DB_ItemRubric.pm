package DB_ItemRubric;

use lib ("/work/perl_lib");

use base qw(ISoft::DB);
use strict;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my $self  = {
	  tablename  => 'bk_data_catalog_item2rubric',
	  idcolumn   => 'id',
	  @_ # init
  };
  $self->{Columns} = {
  	# system fields
  	id         => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	item_id    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, ForeignTable => 'bk_data_catalog_itempage', ForeignKey => 'item_id' },
  	itemrub_id => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, ForeignTable => 'bk_data_catalog_itemrubric', ForeignKey => 'itemrub_id' },
  };
  
  # required fields only!!!
  
  return bless($self, $class);
}


1;
