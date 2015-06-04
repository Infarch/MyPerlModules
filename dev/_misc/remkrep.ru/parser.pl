use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;




use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::ParseEngine::Agents;
use ISoft::ParseEngine::ThreadProcessor;

use ISoft::DBHelper;


# Members
use Category;
use Product;
# of course the classes below might be overriden
#use ISoft::ParseEngine::Member::File::CategoryPicture;
#use ISoft::ParseEngine::Member::File::ProductPicture;
#use ISoft::ParseEngine::Member::File::ProductDescriptionPicture;



parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
	
		Category->new,
		Product->new,
		
		#ISoft::ParseEngine::Member::File::CategoryPicture->new,
		#ISoft::ParseEngine::Member::File::ProductPicture->new,
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
	$tp->cache(1);
	
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
	
	# use existing list
	foreach my $workobj(@init_list){
		
		my $tbname = $workobj->tablename();
		
		my $work = 1;
		my $stop;
		do {
			
			# get a new handler in order to avoid a strange mistake
			my $dbhx = get_dbh();
			my @worklist = $workobj->getWorkList($dbhx, $constants{Parser}{Queue});
			release_dbh($dbhx);
			
			if(@worklist>0){
				print "Enqueue ", scalar @worklist, " items from $tbname\n";
				
				$tp->enqueueMember(@worklist);
				$tp->start($constants{Parser}{Threads});
				$stop = $tp->stop();
				
			} else {
				$work = 0;
			}
		} while ( $work && !$stop );
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
	$root->markDone;
	unless($root->checkExistence($dbh)){
		$root->insert($dbh);
		
		my $agent = LWP::UserAgent->new;
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($agent->get($constants{Parser}{Root_Category})->decoded_content());

		my @topnodes = $tree->findnodes( q{//ul[@id="nav"]/li} );
		foreach my $tn (@topnodes){
			
			my $ta = $tn->findnodes( q{a} )->[0];
			my $name = $ta->findvalue('.');
			$name =~ s/^ //;
			
			my $c0 = Category->new;
			$c0->set('Category_ID', $root->ID);
			$c0->set('URL', $ta->findvalue('@href'));
			$c0->set('Level', 1);
			$c0->set('Name', $name);
			$c0->markDone;
			$c0->insert($dbh);
			
			my @subnodes = $tn->findnodes( q{ul/li} );
			foreach my $sn (@subnodes){
				my $sa = $sn->findnodes( q{a} )->[0];
				my $name = $sa->findvalue('.');
				$name =~ s/^ //;

				my $c1 = Category->new;
				$c0->set('Category_ID', $c0->ID);
				$c1->set('URL', $sa->findvalue('@href'));
				$c1->set('Level', 2);
				$c1->set('Name', $name);
				$c1->insert($dbh);

			}
		}

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
