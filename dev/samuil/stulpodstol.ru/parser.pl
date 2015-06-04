use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;




use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::ParseEngine::ThreadProcessor;


# Members
use Category;
use Product;
# of course the classes below might be overriden
use ISoft::ParseEngine::Member::File::CategoryPicture;
use ISoft::ParseEngine::Member::File::ProductPicture;
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
		
		ISoft::ParseEngine::Member::File::CategoryPicture->new,
		ISoft::ParseEngine::Member::File::ProductPicture->new,
		ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new,
		
		# ...
	);
	foreach my $init_obj (@init_list){
		$init_obj->prepareEnvironment($dbh);
		$dbh->commit();
	}
	
	# at least one object should exist
	check_root($dbh);

	# release the handler
	$dbh->rollback();
	$dbh->disconnect();
	
	# do parsing
	
	my $tp = get_tp();
	
	# use existing list
	foreach my $workobj(@init_list){
		
		my $tbname = $workobj->tablename();
		
		my $work = 1;
		do {
			
			# get a new handler in order to avoid a strange mistake
			my $dbhx = get_dbh();
			my @worklist = $workobj->getWorkList($dbhx, $constants{Parser}{Queue});
			$dbhx->rollback();
			$dbhx->disconnect();
			
			if(@worklist>0){
				print "Enqueue ", scalar @worklist, " items from $tbname\n";
				
				$tp->enqueueMember(@worklist);
				$tp->start($constants{Parser}{Threads});
				
			} else {
				$work = 0;
			}
		} while ( $work );
		
	}

	print "Done\n\n";

	my $fdbh = get_dbh();
	foreach my $obj (@init_list){
		my $tbname = $obj->tablename();
		my $failed = $obj->getFailedCount($fdbh);
		print "$tbname: $failed failed records\n";
	}
	$fdbh->rollback();
	$fdbh->disconnect();
	
		
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

sub get_dbh {
	return ISoft::DB::get_dbh_mysql(
		$constants{Database}{DB_Name},
		$constants{Database}{DB_User},
		$constants{Database}{DB_Password},
		$constants{Database}{DB_Host}
	);
}