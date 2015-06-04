package ISoft::ParseEngine::Logger;

use threads;
use threads::shared;

use strict;
use warnings;

use Thread::Semaphore;

use ISoft::Exception;

use base qw(ISoft::ClassExtender);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
  	logfile => 'log.txt',
  	semaphore => undef,
  	
	  @_ # init
  );
  
  my $obj = bless(shared_clone(\%self), $class);
  $obj->semaphore(new Thread::Semaphore());
}

sub logException {
	my ($self, $exception) = @_;
	
}

sub logMessage {
	my ($self, $msg) = @_;
	$self->semaphore()->down();
	
	
	
	
	$self->semaphore()->up();
	return $self;
}

sub semaphore { return $_[0]->_getset('semaphore', $_[1]); }

1;
