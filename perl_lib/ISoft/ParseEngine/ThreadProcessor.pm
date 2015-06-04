package ISoft::ParseEngine::ThreadProcessor;

use threads;
use threads::shared;

use strict;
use warnings;

use Error ':try';
use HTTP::Cookies;
use LWP::UserAgent;
use Thread::Queue;
#use MIME::Base64;
use Storable qw(freeze thaw);
use Digest::MD5 qw(md5_hex);

use ISoft::DB;
use ISoft::Exception::DB;
use ISoft::Exception::DB::ValidationError;
use ISoft::Exception::NetworkError;
use ISoft::Exception::NetworkError::ProxyError;
use ISoft::Exception::ScriptError;

use ISoft::ParseEngine::Logger;

use base qw(ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  
	  member_queue => undef,
	  logger => undef,
	  cookies => 0,
	  login_provider => undef,
	  
	  cache => 0,
	  cachetable => 'cache',
	  
	  stop => 0,
	  allow_fails => 15,
	  break_on_fatal => 1,
	  
	  dbname => '',
	  dbuser => 'root',
	  dbpassword => 'admin',
	  dbhost => 'localhost',
	  
	  agent_list => [],
	  use_agents => 0,
	  
	  proxy_queue => undef,
	  use_proxy => 0,
	  
	  @_ # init
  );
  
  my $obj = bless(shared_clone(\%self), $class);
  
  $obj->init();
  
  return $obj;
}

sub logDebug {
	my ($self, $data) = @_;
	$self->logger()->logMessage($data);
}

sub logException {
	my ($self, $exception_obj) = @_;
	$self->logger()->logException($exception_obj);
}

sub init {
	my $self = shift;
	
	# queues
	$self->{member_queue} = new Thread::Queue;
	$self->{proxy_queue} = new Thread::Queue;
	
	# logger
	$self->{logger} = ISoft::ParseEngine::Logger->new();
	
	# prepare cache
	if($self->cache()){
		my $ct = $self->{cachetable};
		my $sql = qq!
			CREATE TABLE IF NOT EXISTS `$ct` (
				`Key` CHAR(32) NOT NULL,
				`URL` VARCHAR(500) NOT NULL,
				`Content` LONGBLOB NOT NULL,
				PRIMARY KEY (`Key`)
			);
		!;
		my $dbh = $self->getDbh();
		ISoft::DB::do_query($dbh, sql=>$sql);
		$dbh->commit();
	}
}

sub setLoginProvider {
	my ($self, $provider_obj) = @_;
	# cookies should be enabled in this case
	$self->cookies(1);
	$self->{login_provider} = $provider_obj;
	return $self;
}

sub addProxy {
	my ($self, @proxies) = @_;
	$self->{proxy_queue}->enqueue(@proxies);
	$self->{use_proxy} = 1;
	return $self;
}

sub getProxy {
	my $self = shift;
	if( $self->{use_proxy} ){
		my $proxy = $self->{proxy_queue}->dequeue_nb();
		throw ISoft::Exception::ScriptError(message=>"No proxy") unless $proxy;
		return $proxy;
	}
	return undef;
}

sub addAgent {
	my ($self, @agents) = @_;
	push @{ $self->{agent_list} }, @agents;
	$self->{use_agents} = 1;
	return $self;
}

sub getAgent {
	my $self = shift;
	if ( $self->{use_agents} ){
		my $i = int( rand( @{ $self->{agent_list} } ) );
		return $self->{agent_list}->[$i];
	}
	return undef;
}

sub getUserAgent {
	my $self = shift;
	my $agent = LWP::UserAgent->new;
	if($self->cookies()){
		$agent->cookie_jar( HTTP::Cookies->new() );
	}
	if(defined(my $lp = $self->{login_provider})){
		unless ($lp->login($agent)){
			print "Login failed!\n";
			$agent = undef;
		}
	}
	return $agent;
}

sub getResponse {
	#my ($self, $useragent, $request) = @_;
	
	my ($self, $dbh, $useragent, $member) = @_;
	my $request = $member->getRequest();
	my $key;
	my $url;
	my $cache = $self->cache() && $member->cache();
	if($cache){
		# get md5 of the uri
		$url = $request->uri()->as_string();
		$key = md5_hex($url);
		# look into cache for the key
		my ($row) = ISoft::DB::do_query($dbh, sql=>"select * from `$self->{cachetable}` where `Key`='$key'");
		if(defined $row){
			return thaw($row->{Content});
		}
	}
	
	my $proxy = $self->getProxy();
	if($proxy){
		$useragent->proxy('http', "http://$proxy");
	}
	
	my $agent = $self->getAgent();
	if($agent){
		$useragent->agent($agent);
	}
	
	my $response;

	my $count = 3;
	my $failed = 0;
	do {
		$response = $useragent->request($request);
		$failed = !$response->is_success();
		sleep 1 if $failed;
	} while ($failed && $count--);
	
	if($failed){
		if($proxy){
			throw ISoft::Exception::NetworkError::ProxyError(message=>"Bad proxy $proxy");
		} else {
			throw ISoft::Exception::NetworkError(message=>"Bad response");
		}
	} else {
		# return the proxy to the queue
		$self->addProxy($proxy) if $proxy;

		if($cache){
			# we are here. it means that we are using cache and the requested url does not exist yet in cache table.
			my $serialized = freeze($response);
	 		#$serialized = MIME::Base64::encode($serialized, "");
	 		ISoft::DB::do_query($dbh,
	 			sql => "insert into `$self->{cachetable}` (`Key`, `URL`, `Content`) values (?,?,?)",
	 			values => [$key, $url ,$serialized]
	 		);
		}

		return $response;
	}
	
}

sub worker {
	my $self = shift;
	
	my $agent = $self->getUserAgent()
		or $self->stop(1);
	
	my $dbh = $self->getDbh();

	my $begin = '...';
	my $bl = length $begin;
	my $limit = 79;
	
	my $noblock = 1;
	my $member;
	my $member_id;
	while ( !$self->stop() && ($member = $self->dequeueMember($noblock)) ){

		# do job

		my $url = $member->get('URL');
		$member_id = $member->ID;
		# dont print too long urls
		if ((my $l = length $url) > $limit){
			my $newtext = substr($url, $l - $limit + $bl);
			print "$begin$newtext\n";
		} else {
			print $url, "\n";
		}
		
		my $message;
		my $break_application;
		my $exception;
		
		try {
			
			#my $request = $member->getRequest();
			my $response = $self->getResponse($dbh, $agent, $member);
			$member->processResponse($dbh, $response);
			$dbh->commit();

		} catch ISoft::Exception with {
			$exception = $@;
			$message = $@->longMessage();
		} otherwise {
			$exception = $@;
			$message = $@;
		};

		# restore status after error
		if(defined $exception){
			print "\nError happened during processing of $member->{tablename}:$member_id\n$message\n\n";
			try {
				# discard changes
				$dbh->rollback();
				
				# get the error's importance value (0..15);
				my $weight = $member->getExceptionWeight($exception);
				$break_application = $weight == -1;
				unless ($break_application && $self->breakOnFatal()){
					my $xmember = $member->new;
					$xmember->set('ID', $member_id);
					$xmember->select($dbh);
					if($break_application){
						# just make the member 'failed'
						$xmember->markFailed();
						# release the error flag
						$break_application = 0;
					} else {
						# update error counter
						my $errors = $xmember->get('Errors') + $weight;
						$xmember->set('Errors', $errors);
						if($errors > $self->allowFails()){
							$xmember->markFailed();
						}
					}
					$xmember->update($dbh);
					$dbh->commit();
				}
				
			} otherwise {
				print "Cannot restore status after error. Going to shutdown\n";
				$break_application = 1;
			};
		}
		
		$self->stop(1) if $break_application;
		
		$member = undef;
		threads->yield();
		
	}
	
	$dbh->rollback();
	$dbh->disconnect();

}

sub start {
	my ($self, $threads) = @_;
	$threads = $threads || 1;
	
	my $count = 0;
	foreach (1..$threads){
		$count++ 
			if defined threads->create( 'worker', $self );
	}
	
	while ($count){
		sleep 3;
		
		my @joinable = threads->list(threads::joinable);
		foreach my $thrd (@joinable){
			$thrd->join();
			$count--;
		}
		
	}
	
}

sub dequeueMember {
	my ($self, $noblock) = @_;
	
	if($noblock){
		return $self->{member_queue}->dequeue_nb();
	} else {
		return $self->{member_queue}->dequeue();
	}
	
}

sub enqueueMember {
	my ($self, @list) = @_;
	$self->{member_queue}->enqueue(@list);
}

sub getDbh {
	my $self = shift;
	return ISoft::DB::get_dbh_mysql($self->dbName(), $self->dbUser(),
		$self->dbPassword(), $self->dbHost());
}

# simple getters / setters
sub breakOnFatal { return $_[0]->_getset('break_on_fatal', $_[1]); }

sub logger { return $_[0]->_getset('logger', $_[1]); }

sub dbName { return $_[0]->_getset('dbname', $_[1]); }

sub dbUser { return $_[0]->_getset('dbuser', $_[1]); }

sub dbPassword { return $_[0]->_getset('dbpassword', $_[1]); }

sub dbHost { return $_[0]->_getset('dbhost', $_[1]); }

sub stop { return $_[0]->_getset('stop', $_[1]); }

sub allowFails { return $_[0]->_getset('allow_fails', $_[1]); }

sub cookies { return $_[0]->_getset('cookies', $_[1]); }

sub cache { return $_[0]->_getset('cache', $_[1]); }

1;
