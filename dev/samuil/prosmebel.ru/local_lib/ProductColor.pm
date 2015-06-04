package ProductColor;

use strict;
use warnings;

use ProductColorPicture;

use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'ProductColor',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID         => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Product_ID => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, ForeignTable => 'Product', ForeignKey => 'ID' },
  	Name       => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 256 },
  	Type       => { Type => $ISoft::DB::TYPE_TINYINT, NotNull => 1, Default => 0 },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

sub getPicture {
	my($self, $dbh) = @_;
	my $obj = ProductColorPicture->new;
	$obj->set("Color_ID", $self->ID);
	$obj->markDone();
	return $obj if $obj->checkExistence($dbh);
	return undef;
}

1;
