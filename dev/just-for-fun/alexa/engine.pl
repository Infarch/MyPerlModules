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


use DB_Member;
use Parsers;


# get configuration

# database connection settings
our $db_name:shared = $constants{Database}{DB_Name};
our $db_user:shared = $constants{Database}{DB_User};
our $db_pass:shared = $constants{Database}{DB_Pass};
our $db_host:shared = $constants{Database}{DB_Host};


our $site_root:shared = $constants{General}{Site_Root};
our $process_categories_once:shared = $constants{Category}{Process_Once};
our $categories_vs_products:shared = $constants{Category}{Categories_vs_Products};
our $product_has_picture:shared = $constants{Product}{Has_Picture};
our $product_has_many_pictures:shared = $constants{Product}{Many_Pictures};
our $product_description_has_pictures:shared = $constants{Product}{Description_With_Pictures};
our $files_directory:shared = $constants{General}{Files_Directory};
our $echo_url:shared = $constants{Debug}{Echo_Url};
our $echo_time:shared = $constants{Debug}{Echo_Time};
our $echo_stat:shared = $constants{Debug}{Echo_Statistic};
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

sub process_file {
	my ($dbh, $member_obj, $response) = @_;

	my $id = $member_obj->ID;
	my $path = "$files_directory/$id";
	save_file($path, $response);
	
	$member_obj->update($dbh);
}

sub save_file {
	my ($name, $resp) = @_;
	open (XX, '>', $name) or throw ISoft::Exception::ScriptError(message=>"Error creating file: $!");
	binmode XX;
	print XX $resp->content();
	close XX;
}

############################ Category functions ############################

sub process_subcategories {
	my ($dbh, $member_obj, $tree) = @_;
	
	my $level = $member_obj->Level();
	
	# call a function from Parsers.pm
	my $sc_list = get_categories($tree, $level);
	
	my $member_id = $member_obj->ID;
	$level += 1;
	
	foreach my $category (@$sc_list){
		my $new_member_obj = DB_Member->new;
		$new_member_obj->Member_ID($member_id);
		$new_member_obj->Level($level);
		$new_member_obj->Type($DB_Member::TYPE_CATEGORY);
		$new_member_obj->Status($DB_Member::STATUS_READY);
		$new_member_obj->setByHash($category);
		$new_member_obj->insert($dbh);
	}
	
	return scalar @$sc_list;
}

sub process_category {
	my ($dbh, $member_obj, $response) = @_;
	
	my $tree = get_tree($response);
	
	my $page = $member_obj->Page();
	my $sc_count = 0;
	if($page==1){
		# only first page might contain sub categories.
		$sc_count = process_subcategories($dbh, $member_obj, $tree);
	}
	
	if(!$categories_vs_products || $sc_count==0){
		process_products($dbh, $member_obj, $tree);
		
		# as a rule, only Products page can have the 'next' option
		
		# call a function from Parsers.pm
		if(my $nextpage = get_next_page($tree)){
			$member_obj->Page($page+1);
			$member_obj->NextURL($nextpage);
			$member_obj->Status($DB_Member::STATUS_READY);
		}
		
	}
	
	$member_obj->update($dbh);
	$tree->delete();
}

############################ Product functions ############################

sub process_products {
	my ($dbh, $member_obj, $tree) = @_;
	# call a function from Parsers.pm
	my $prodlist = get_products($tree);
	my $member_id = $member_obj->ID;
	foreach my $product (@$prodlist){
		my $new_member_obj = DB_Member->new;
		$new_member_obj->Member_ID($member_id);
		$new_member_obj->Type($DB_Member::TYPE_PRODUCT);
		$new_member_obj->Status($DB_Member::STATUS_READY);
		$new_member_obj->setByHash($product);
		$new_member_obj->insert($dbh);
	}
}

sub process_product {
	my ($dbh, $member_obj, $response) = @_;
	my $tree = get_tree($response);
	# call a function from Parsers.pm
	my $info = get_product_info($tree);
	if($product_description_has_pictures && exists $info->{FullDescription}){
		$info->{FullDescription} = process_description_pictures($dbh, $member_obj, $info->{FullDescription});
	}
	$member_obj->setByHash($info);
	$member_obj->update($dbh);
	
	my $member_id = $member_obj->ID;
	
	# process picture(s)
	my @pictures;

	if($product_has_picture){
		# call a function from Parsers.pm
		push @pictures, get_product_picture($tree);
	}

	if($product_has_many_pictures){
		# call a function from Parsers.pm
		push @pictures, @{ get_product_additional_pictures($tree) };
	}
	
	foreach my $picture (@pictures){
		my $new_member_obj = DB_Member->new;
		$new_member_obj->Member_ID($member_id);
		$new_member_obj->Type($DB_Member::TYPE_PICTURE);
		$new_member_obj->Status($DB_Member::STATUS_READY);
		$new_member_obj->setByHash($picture);
		$new_member_obj->insert($dbh);
	}
	
	$tree->delete();
}

sub process_description_pictures {
	my ($dbh, $member_obj, $text) = @_;
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($text);
	my @picnodes = $tree->findnodes( q{//img} );
	my $member_id = $member_obj->ID;
	foreach my $node (@picnodes){
		my $pic_member_obj = DB_Member->new;
		$pic_member_obj->Member_ID($member_id);
		$pic_member_obj->URL($node->attr('src'));
		$pic_member_obj->Type($DB_Member::TYPE_DESCRIPTION_PICTURE);
		$pic_member_obj->Status($DB_Member::STATUS_READY);
		$pic_member_obj->insert($dbh);
		$node->attr('member', $pic_member_obj->ID);
	}
	my $html = $tree->as_HTML('<>&');
	$tree->delete();
	return $html;
}

############################ Engine functions ############################

sub get_tree {
	my $response = shift;
	my $content = $response->decoded_content();
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	return $tree;
}

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
	my ($ua, $url, $noproxy) = @_;
	
	my $proxy;
	if($use_proxy && !$noproxy){
		$proxy = $qProxy->dequeue_nb();
		throw ISoft::Exception::ScriptError(message=>"No proxy") unless $proxy;
		$ua->proxy('http', "http://$proxy");
	}
	
	set_agent($ua);
	
	my $resp = $ua->get($url);
	
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
		
		# this status can be overriden
		$member_obj->Status($DB_Member::STATUS_DONE);
		
		my $error = 0;
		my $message = '';
		my $url;
		try {
			
			# get/restore database handler
			$dbh = get_dbh() unless defined $dbh;
			
			# processing of each member starts with getting its content.
			# if a member have Page=1 then we use URL else NextURL
			$url = $member_obj->Page()==1 ? $member_obj->URL() : $member_obj->NextURL();
			
			print "$url\n" if $echo_url;
			
			$url = URI->new($url)->abs($site_root);
			
			# select action
			if($member_obj->isCategory()){
				process_category($dbh, $member_obj, get_response($ua, $url));
			} elsif($member_obj->isProduct()){
				process_product($dbh, $member_obj, get_response($ua, $url));
			} elsif ($member_obj->isPicture() || $member_obj->isDescriptionPicture()){
				# no proxy for static content
				process_file($dbh, $member_obj, get_response($ua, $url, 1));
			} else {
				throw ISoft::Exception::ScriptError(message=>"Unknown member type");
			}
			
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
					$member_obj = DB_Member->new;
					$member_obj->set('ID', $id);
					$member_obj->select($dbh);
					my $errors = $member_obj->Errors + $error;
					$member_obj->Errors($errors);
					if($errors > $allow_fails){
						$member_obj->Status($DB_Member::STATUS_FAILED);
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
		my @objlist = get_opened_members($dbh, $constants{General}{Threads}*50);
		$dbh->rollback();
		$dbh->disconnect();
		if(@objlist>0){
			
			if($echo_time){
				my $tm = localtime(time);
				print "$tm\n";
			}
			
			if($echo_stat){
				statistic();
			}
			
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

	# directory for files
	unless (-e $files_directory && -d $files_directory){
		mkdir $files_directory or throw ISoft::Exception::ScriptError(message=>"Cannot create files directory: $!");
	}
	
	# proxy list
	if ($use_proxy){
		init_proxy();
	}
	
	init_agent();
	
	srand();
	
	my $dbh = get_dbh();
	
	my $member_obj = DB_Member->new;
	$member_obj->Member_ID(undef);
	$member_obj->set('Name', $constants{General}{Root_Category_Name});
	$member_obj->URL($constants{General}{Root_Category_Url});
	$member_obj->Type($DB_Member::TYPE_CATEGORY);
	
	if(!$member_obj->checkExistence($dbh)){
		print "First start\n";
		$member_obj->Status($DB_Member::STATUS_READY);
		$member_obj->insert($dbh);
		$dbh->commit();
	} else {
		print "Continue work\n";
		
	}
	$dbh->rollback();
	$dbh->disconnect();
}



sub get_dbh {
	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass, $db_host);
}

sub get_opened_members {
	my ($dbh, $count) = @_;
	my $member_obj = DB_Member->new;
	$member_obj->Status($DB_Member::STATUS_READY);
	$member_obj->maxReturn($count) if $count;
	my @list = $member_obj->listSelect($dbh);
	
	return @list;
}

