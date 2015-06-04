package DB_Item;

use lib ("/work/perl_lib");

use base qw(ISoft::DB);
use strict;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my $self  = {
	  tablename     => 'bk_data_catalog_itempage',
	  item_title_ru => 'itemrub_title_ru',
	  idcolumn      => 'item_id',
	  @_ # init
  };
  $self->{Columns} = {
  	# system fields
  	item_id        => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	item_title_ru  => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	item_body_ru   => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	item_anonce_ru => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	item_photo     => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	item_photo_big => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	item_price     => { Type => $ISoft::DB::TYPE_MONEY,   Updated => 0, Value => undef },
  	st             => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  };
  
  # required fields only!!!
  
  return bless($self, $class);
}


1;
