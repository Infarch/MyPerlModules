package DB_Prototype;

use threads;
use threads::shared;

use HTTP::Request;
use HTTP::Response;

use lib ("/work/perl_lib");
use ISoft::Exception::ScriptError;

use base qw(ISoft::DB);
use strict;

use constant {
	STATUS_NEW => 1,
	STATUS_PROCESSING => 2,
	STATUS_DONE => 3,
	STATUS_FAILED => 4
};


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'Member',
	  namecolumn => 'Name',
	  Columns    => {},
	  @_ # init
  );
  return bless(shared_clone(\%self), $class);
}

sub _getset {
	my ($self, $field, $newvalue) = @_;
	my $old = $self->get($field);
	$self->set($field, $newvalue) if defined $newvalue;
	return $old;
}

sub getRequest {
	throw ISoft::Exception::ScriptError(message=>"Abstract method called");
}

sub processResponse {
	my ($self, $dbh, $response) = @_;
	throw ISoft::Exception::ScriptError(message=>"Abstract method called");
}
1;
