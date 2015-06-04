package Property;

use strict;
use warnings;

use lib ("/work/perl_lib");

# base class
use base qw(ISoft::DB ISoft::ClassExtender);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'Property',
	  namecolumn => 'Name',
	  @_ # init
  );
  
  $self{Columns} = {
  	ID          => { Type => $ISoft::DB::TYPE_INT,     NotNull => 1, PrimaryKey => 1 },
  	Product_ID  => { Type => $ISoft::DB::TYPE_INT,     NotNull => 1, ForeignTable => 'Product' , ForeignKey => 'ID'},
  	Name        => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 100 },
  	Value       => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 2000 },
  	State       => { Type => $ISoft::DB::TYPE_BIT,     NotNull => 1 },
  	newValue    => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 2000 },
  	newValue2   => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 2000 },
  	Ignore      => { Type => $ISoft::DB::TYPE_BIT,     NotNull => 1 },
  };
  
  my $self = bless(\%self, $class);
  
  return $self;
}

# this functions inserts appropriate table into database.
# furthermore, child objects could use the function for creating required folders, etc.
# don't forget to call the base function from child objects
sub prepareEnvironment {
	my ($self, $dbh) = @_;
	my $sql = $self->buildTableSql();
	ISoft::DB::do_query($dbh, sql=>$sql);
}



1;
