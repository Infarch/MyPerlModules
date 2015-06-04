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
# of course the classes below might be overriden
use ISoft::ParseEngine::Member::File::ProductPicture;


parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
	
		Category->new,
		Product->new,
		
		ISoft::ParseEngine::Member::File::ProductPicture->new,
		
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
	unless($root->checkExistence($dbh)){
		$root->markDone();
		$root->insert($dbh);
		
		my @subs = (
			['http://www.troika.org/en/produkte/uebersicht.html?kat=20', 'Andy Warhol'],
			['http://www.troika.org/en/produkte/uebersicht.html?kat=21', 'Karim Rashid'],
			['http://www.troika.org/en/produkte/uebersicht.html?kat=22', 'Lufthansa']
		);
		
		foreach my $sc (@subs){
			my $cat = Category->new;
			$cat->set('URL', $sc->[0]);
			$cat->set('Name', $sc->[1]);
			$cat->set('Level', 1);
			$cat->set('Category_ID', $root->ID);
			$cat->insert($dbh);
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
