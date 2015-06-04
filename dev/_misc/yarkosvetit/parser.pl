use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;




use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::ParseEngine::Agents;
use ISoft::ParseEngine::ThreadProcessor;

use ISoft::DBHelper;


# Members
use Category;
use Product;
use Property;
use ProductPicture;

# of course the classes below might be overriden
use ISoft::ParseEngine::Member::File::CategoryPicture;

use ISoft::ParseEngine::Member::File::ProductDescriptionPicture;




parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
	
		Category->new,
		Product->new,
		Property->new,
		
		#ISoft::ParseEngine::Member::File::CategoryPicture->new,
		ProductPicture->new,
		#ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new,
		
		# ...
	);
	foreach my $init_obj (@init_list){
		$init_obj->prepareEnvironment($dbh);
		$dbh->commit();
	}
	
	# at least one object should exist
	check_root($dbh);

	# release the handler
	release_dbh($dbh);
	
	# do parsing
	
	# instantiate the ThreadProcessor
	my $tp = get_tp();
	
	if(1){
		# use agent list
		$tp->addAgent(@agents);
	}
	
	if(0){
		# use proxy list
		my @proxylist;
		load_list('proxy.txt', \@proxylist);
		$tp->addProxy(@proxylist);
	}

	if(0){
		my $login_obj = ISoft::ParseEngine::Login::xxx->new(
			username => 'somename',
			password => '******',
			login_url => 'http://www.example.com/login.php'
		);
		$tp->setLoginProvider($login_obj);
	}
	
	# use existing list
	# start parsing
	while(1){
		my $stop;
		my $left = $constants{Parser}{Queue};
		
		print "Start reading DB...\n";
		
		my $dbhx = get_dbh();
		my @worklist;
		foreach my $workobj(@init_list){
			my $limit = $left - @worklist;
			last if $limit==0;
			my @tmp = $workobj->getWorkList($dbhx, $limit) if $workobj->can('getWorkList');
			push @worklist, @tmp;
		}
		release_dbh($dbhx);
		
		if(@worklist>0){
			print "Enqueue ", scalar @worklist, " items\n";
			$tp->enqueueMember(@worklist);
			$tp->start($constants{Parser}{Threads});
			$stop = $tp->stop();
		} else {
			last;
		}
		
		last if $stop;
		
	}

	if($tp->stop()){
		print "Thread processor stopped!!!\n\n";
	} else {
		print "Done\n\n";
	}

	my $fdbh = get_dbh();
	foreach my $obj (@init_list){
		my $tbname = $obj->tablename();
		my $failed = $obj->getFailedCount($fdbh);
		print "$tbname: $failed failed records\n";
	}
	release_dbh($fdbh);
}

sub check_root {
	my $dbh = shift;
	
	# make root
	my $root = Category->new;
	$root->set('URL', $constants{Parser}{Root_Category});
	$root->set('Level', 0);
	unless($root->checkExistence($dbh)){
		$root->insert($dbh);
		$dbh->commit();
	}
	
}

# creates an instance of the ThreadProcessor class
sub get_tp {
	return new ISoft::ParseEngine::ThreadProcessor(
		dbname=>$constants{Database}{DB_Name},
		dbuser => $constants{Database}{DB_User},
		dbpassword => $constants{Database}{DB_Password},
		dbhost => $constants{Database}{DB_Host}
	);
}

sub load_list {
	my ($file, $list_ref) = @_;
	return 0 unless open SRC, $file;
	while (<SRC>){
		chomp;
		push @$list_ref, $_;
	}
	close SRC;
	if(@$list_ref>0){
		$list_ref->[0] =~ s/^\xEF\xBB\xBF//;
	}
	return 1;
}
