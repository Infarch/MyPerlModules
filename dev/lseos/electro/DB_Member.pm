package DB_Member;

use lib ("/work/perl_lib");

use base qw(ISoft::DB);
use strict;


$DB_Member::TYPE_CATEGORY = 1;
$DB_Member::TYPE_PRODUCT  = 2;
$DB_Member::TYPE_PICTURE  = 3;
$DB_Member::TYPE_FILE     = 4;

$DB_Member::STATUS_READY = 1;
$DB_Member::STATUS_PROCESSING = 2;
$DB_Member::STATUS_DONE = 3;

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my $self  = {
	  tablename  => 'Member',
	  namecolumn => 'Name',
	  @_ # init
  };
  $self->{Columns} = {
  	# system fields
  	ID        => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	Memder_ID => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, ForeignTable => 'Member', ForeignKey => 'ID' },
  	URL       => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Type      => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Status    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Page      => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	# data fields
  	ShortDescription => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	FullDescription  => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	Name       => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	InternalID => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Vendor     => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Price      => { Type => $ISoft::DB::TYPE_MONEY,   Updated => 0, Value => undef },
  	
  };
  return bless($self, $class);
}

sub URL {
	my $self = shift;
	return $self->get('URL');
}

sub isCategory {
	my $self = shift;
	return $self->get('Type')==$DB_Member::TYPE_CATEGORY;
}

sub isProduct {
	my $self = shift;
	return $self->get('Type')==$DB_Member::TYPE_PRODUCT;
}

sub isPicture {
	my $self = shift;
	return $self->get('Type')==$DB_Member::TYPE_PICTURE;
}

sub isFile {
	my $self = shift;
	return $self->get('Type')==$DB_Member::TYPE_FILE;
}

1;
