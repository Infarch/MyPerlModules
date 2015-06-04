package DB_LiveUser;

use threads;
use threads::shared;

use base qw(DB_Prototype);
use strict;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'LiveUser',
	  namecolumn => 'Nick',
	  Columns    => {
	  	ID        => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
	  	Nick      => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
	  	URL       => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
	  	Status    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
	  	Errors    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
	  },
	  @_ # init
  );
  return bless(shared_clone(\%self), $class);
}


sub URL       { return $_[0]->_getset('URL', $_[1]); }
sub Status    { return $_[0]->_getset('Status', $_[1]); }
sub Errors    { return $_[0]->_getset('Errors', $_[1]); }
sub Nick      { return $_[0]->_getset('Nick', $_[1]); }


1;
