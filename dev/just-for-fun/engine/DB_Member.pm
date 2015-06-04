package DB_Member;

use threads;
use threads::shared;

use lib ("/work/perl_lib");

use base qw(ISoft::DB);
use strict;


$DB_Member::TYPE_CATEGORY = 1;
$DB_Member::TYPE_PRODUCT  = 2;
$DB_Member::TYPE_PICTURE  = 3;
$DB_Member::TYPE_DESCRIPTION_PICTURE = 4;

$DB_Member::STATUS_READY      = 1;
$DB_Member::STATUS_PROCESSING = 2;
$DB_Member::STATUS_DONE       = 3;
$DB_Member::STATUS_FAILED     = 4;

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'Member',
	  namecolumn => 'Name',
	  @_ # init
  );
  $self{Columns} = {
  	# system fields
  	ID        => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	Member_ID => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, ForeignTable => 'Member', ForeignKey => 'ID' },
  	URL       => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	NextURL   => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Type      => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Status    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Level     => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Page      => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Errors    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	# common data fields
  	ShortDescription => { Type => $ISoft::DB::TYPE_TEXT, Updated => 0, Value => undef },
  	FullDescription  => { Type => $ISoft::DB::TYPE_TEXT, Updated => 0, Value => undef },
  	Name        => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	InternalID  => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Vendor      => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Price       => { Type => $ISoft::DB::TYPE_MONEY,   Updated => 0, Value => undef },
  	# spare fields for unrecognized data
  	#CustomVarc1 => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	#CustomVarc2 => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	#CustomVarc3 => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	#CustomText1 => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	#CustomText2 => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  	#CustomText3 => { Type => $ISoft::DB::TYPE_TEXT,    Updated => 0, Value => undef },
  };
  return bless(shared_clone(\%self), $class);
}

# object properties - system fields only

sub _getset {
	my ($field, $self, $newvalue) = @_;
	my $old = $self->get($field);
	$self->set($field, $newvalue) if defined $newvalue;
	return $old;
}

sub Member_ID {	return _getset('Member_ID', @_); }
sub URL       { return _getset('URL', @_); }
sub NextURL   { return _getset('NextURL', @_); }
sub Type      { return _getset('Type', @_); }
sub Status    { return _getset('Status', @_); }
sub Level     { return _getset('Level', @_); }
sub Page      { return _getset('Page', @_); }
sub Errors    { return _getset('Errors', @_); }


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

sub isDescriptionPicture {
	my $self = shift;
	return $self->get('Type')==$DB_Member::TYPE_DESCRIPTION_PICTURE;
}

1;
