package DB_Rubric;

use lib ("/work/perl_lib");

use base qw(ISoft::DB);
use strict;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my $self  = {
	  tablename  => 'bk_data_catalog_itemrubric',
	  namecolumn => 'itemrub_title_ru',
	  idcolumn   => 'itemrub_id',
	  @_ # init
  };
  $self->{Columns} = {
  	# system fields
  	itemrub_id       => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	itemrub_pid      => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, ForeignTable => 'bk_data_catalog_itemrubric', ForeignKey => 'itemrub_id' },
  	itemrub_title_ru => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	st               => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  };
  
  # required fields only!!!
  
  return bless($self, $class);
}


1;
