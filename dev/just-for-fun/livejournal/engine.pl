use threads;
use threads::shared;

use strict;
use warnings;

use Encode 'decode';
use Error qw(:try);
use LWP::Simple 'get';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Thread::Queue;
use Thread::Semaphore;
use URI;

use lib ("/work/perl_lib");
use ISoft::Conf;
use ISoft::DB;
use ISoft::Exception;
use ISoft::Exception::DB;
use ISoft::Exception::NetworkError;
use ISoft::Exception::ScriptError;

use DB_Page;


# get configuration

# database connection settings
our $db_name:shared = $constants{Database}{DB_Name};
our $db_user:shared = $constants{Database}{DB_User};
our $db_pass:shared = $constants{Database}{DB_Pass};
our $db_host:shared = $constants{Database}{DB_Host};


#our $site_root:shared = $constants{General}{Site_Root};
#our $process_categories_once:shared = $constants{Category}{Process_Once};
#our $categories_vs_products:shared = $constants{Category}{Categories_vs_Products};
#our $product_has_picture:shared = $constants{Product}{Has_Picture};
#our $product_has_many_pictures:shared = $constants{Product}{Many_Pictures};
#our $product_description_has_pictures:shared = $constants{Product}{Description_With_Pictures};
#our $files_directory:shared = $constants{General}{Files_Directory};

our $echo_url:shared = $constants{Debug}{Echo_Url};
our $echo_time:shared = $constants{Debug}{Echo_Time};
our $allow_fails:shared = $constants{General}{Allow_Fails};

our $use_proxy:shared = $constants{Proxy}{Use_Proxy};
our %proxy_registry:shared;
our $qProxy:shared;

our $useragent:shared = '';
our @agent_list:shared;

# auxiliary variables
our $break_application:shared = 0;


local $SIG{INT} = sub{
	# interrupt handler. useful for finalization after that user has pressed Ctrl+C
	print "Break signalled, please wait for finish\n";
	$break_application = 1;
	exit;
};


# begin work

# the three lines below do not make sense but allows to avoid a strange error in threads
my $dbhx = get_dbh();
$dbhx->rollback();
$dbhx->disconnect();

my $queue = Thread::Queue->new();
my $sem = Thread::Semaphore->new(0);
init();
make_threads($queue, $sem);
start($queue, $sem);
finalize();

exit;

############################ File functions ############################


sub save_file {
	my ($name, $resp) = @_;
	open (XX, '>', $name) or throw ISoft::Exception::ScriptError(message=>"Error creating file: $!");
	binmode XX;
	print XX $resp->content();
	close XX;
}

############################ Engine functions ############################


sub set_agent {
	my $ua = shift;
	if ($useragent){
		$ua->agent($useragent);
	} elsif (my $len = @agent_list) {
		# get random agent
		my $pos = int( rand($len) );
		$ua->agent($agent_list[$pos]);
	}
}

# we will use a separate function for getting response since it is helpful when we use proxy list
sub get_response {
	my ($ua, $request, $noproxy) = @_;
	
	my $proxy;
	if($use_proxy && !$noproxy){
		$proxy = $qProxy->dequeue_nb();
		throw ISoft::Exception::ScriptError(message=>"No proxy") unless $proxy;
		$ua->proxy('http', "http://$proxy");
	}
	
	set_agent($ua);
	
	my $resp = $ua->request($request);
	
	if($proxy){
		
		lock %proxy_registry;
		
		if($resp->is_success()){
			# mark this proxy as Ok
			$proxy_registry{$proxy} = 0;
		} else {
			# mark this proxy as Bad
			my $count = exists $proxy_registry{$proxy} ? $proxy_registry{$proxy}+1 : 1;
			$proxy_registry{$proxy} = $count;
			if($count==3){
				delete $proxy_registry{$proxy};
				print "Proxy $proxy was permanently removed from queue after 3 errors\n";
				print scalar keys %proxy_registry, " proxies left\n";
				$proxy = '';
			}
		}
		# return to queue
		$qProxy->enqueue($proxy) if $proxy;
	}
		
	throw ISoft::Exception::NetworkError(message=>"Network error")
		unless $resp->is_success();
	return $resp;
}

sub worker {
	my ($queue, $sem) = @_;
	
	# prepare utility objects
	my $ua = LWP::UserAgent->new();
	# set reasonable timeout value
	$ua->timeout(20);
	
	my $dbh;
	
	while ( defined( my $member_obj = $queue->dequeue() ) ){
		$sem->up();
		
		my $error = 0;
		my $message = '';
		my $url;
		try {
			
			# get/restore database handler
			$dbh = get_dbh() unless defined $dbh;
			
			my $request = $member_obj->getRequest();
			$url = $request->uri()->as_string();
			
			print "$url\n" if $echo_url;
			
			my $resp = get_response($ua, $request);
			$member_obj->processResponse($dbh, $resp);
						
		} catch ISoft::Exception::DB with {
			
			# not fatal, but the member should be processed again
			$error = 5; # heavy error weight
			$message = $@->longMessage();
			
		} catch ISoft::Exception::ScriptError with {

			# fatal for application in whole
			
			$message = $@->longMessage();
			$error = 1;
			$break_application = 1;
			
		} catch ISoft::Exception::NetworkError with {
			
			# not fatal, try again
			$error = 1;
			$message = $@->longMessage();
			
		} otherwise {
			# fatal for application in whole
			
			$message = $@;
			$error = 1;
			$break_application = 1;
			
		};

		# restore status after error
		if($error){
			print "\nError happened during processing of $url: $message\n\n";
			try {
				# discard changes
				$dbh->rollback();

				unless ($break_application){
					my $id = $member_obj->ID;
					$member_obj = $member_obj->new;
					$member_obj->set('ID', $id);
					$member_obj->select($dbh);
					my $errors = $member_obj->Errors + $error;
					$member_obj->Errors($errors);
					if($errors > $allow_fails){
						$member_obj->Status($member_obj->STATUS_FAILED);
					}
					$member_obj->update($dbh);
				}
				
			} otherwise {
				print "Cannot restore status after error. Going to shutdown\n";
				$break_application = 1;
			};
			
		}
		
		$dbh->commit() unless $break_application;
		
		$sem->down();
		
		last if $break_application;
		
		threads->yield();
		
	}
	
}

# deprecated
sub statistic {
	my $dbh = get_dbh();

	# read the existing types
	my $sql = 'select distinct type from member';
	my @types = ISoft::DB::do_query($dbh, sql=>$sql, arr_ref=>1);
	
	# get statistic for each the type
	foreach my $typeref (@types){
		my $type = $typeref->[0];
		$sql = qq(
			select * from (
				(select count(*) as ready from member where status=1 and type=$type) as x,
				(select count(*) as done from member where status=3 and type=$type) as y,
				(select count(*) as failed from member where status=4 and type=$type) as z
			)
		);
		
		my @clist = ISoft::DB::do_query($dbh, sql=>$sql, arr_ref=>1);
		my $row = shift @clist;
		
		print "Type $type:   $row->[0] / $row->[1] / $row->[2]\n";
	}
	
	$dbh->rollback();
	$dbh->disconnect();

}

sub start {
	my ($queue, $sem) = @_;
	my $stop = 0;
	do {
		my $dbh = get_dbh();
		my @objlist = get_new_members($dbh, $constants{General}{Threads}*50);
		$dbh->rollback();
		$dbh->disconnect();
		if(@objlist>0){
			
			if($echo_time){
				my $tm = localtime(time);
				print "$tm\n";
			}
			
			#if($echo_stat){
			#	statistic();
			#}
			
			foreach my $obj(@objlist){
				$queue->enqueue($obj);
			}
			my $work = 1;
			do {
				sleep 5;
				{
					lock $$sem;
					if(($queue->pending()==0 || $break_application) && $$sem==0){
						$work = 0;
					}
				}
			} while($work);
		} else {
			$stop = 1;
		}
	} while (!$stop && !$break_application);
}

sub make_threads {
	my ($queue, $sem) = @_;
	foreach (1..$constants{General}{Threads}){
		threads->create( 'worker', $queue, $sem )->detach();
	}
}

sub init_agent(){
	$useragent = exists $constants{UserAgent}{Agent_Name} ? $constants{UserAgent}{Agent_Name} : '';
	my $listname = exists $constants{UserAgent}{Agent_List} ? $constants{UserAgent}{Agent_List} : '';
	if ($listname){
		open (LST, $listname) or throw ISoft::Exception::ScriptError(message=>"Cannot open $listname: $!");
		while (<LST>){
			chomp;
			push @agent_list, $_;
		}
		close LST;
	}
}

sub init_proxy {
	$qProxy = Thread::Queue->new;
	my $listname = $constants{Proxy}{Proxy_List};
	open (SRC, $listname) or throw ISoft::Exception::ScriptError(message=>"Cannot open $listname: $!");
	while (<SRC>){
		chomp;
		$qProxy->enqueue("$_");
	}
	close SRC;
	if($qProxy->pending()==0){
		throw ISoft::Exception::ScriptError(message=>"No proxies");
	} elsif($qProxy->pending()<10){
		print "Please note that your proxy list is not enough full\n";
	}
}

# performs finalization
sub finalize {
	# if we are using proxy list then the %proxy_registry hash contains addresses of alive proxy servers.
	# it makes sense to store the data in order to avoid checking of proxy list after next start.
	my @list = keys %proxy_registry;
	open P, '>', $constants{Proxy}{Backup_List};
	foreach (@list){
		print P "$_\n";
	}
	close P;
}

sub init {

	# proxy list
	if ($use_proxy){
		init_proxy();
	}
	
	init_agent();
	
	srand();
	
	my $dbh = get_dbh();
	
	my $page_obj = DB_Page->new;
	$page_obj->URL('http://www.livejournal.com/ratings/users/?page=1');
	if(!$page_obj->checkExistence($dbh)){
		print "First start\n";
		populate_db($dbh);
		$dbh->commit();
	} else {
		print "Continue work\n";
		$dbh->rollback();
	}
	
	$dbh->disconnect();
}

sub populate_db {
	my $dbh = shift;
	
	for(my $i=1; $i<182196; $i++){
		my $obj = DB_Page->new;
		$obj->URL("http://www.livejournal.com/ratings/users/?page=$i");
		$obj->Status($obj->STATUS_NEW);
		$obj->insert($dbh);
		
		if($i % 20000 == 0){
			print "$i\n";
		}
	}
	
	
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass, $db_host);
}

sub get_new_members {
	my ($dbh, $count) = @_;
	
	my @memberlist = (
		DB_Page->new()
	);
	
	my @list;
	
	foreach my $member_obj (@memberlist){
		my $temp_obj = $member_obj->new;
		$temp_obj->Status($temp_obj->STATUS_NEW);
		$temp_obj->maxReturn($count) if $count;
		@list = $temp_obj->listSelect($dbh);
		last if @list > 0;
	}
	
	return @list;
}

