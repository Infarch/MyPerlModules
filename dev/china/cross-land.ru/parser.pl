use strict;
use warnings;

use utf8;

# parse data



use Error ':try';
use LWP::UserAgent;




use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::ParseEngine::Agents;
use ISoft::ParseEngine::ThreadProcessor;


# Members
use Album;
use ISoft::ParseEngine::Member::File::Photo;



parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
		Album->new,
		ISoft::ParseEngine::Member::File::Photo->new,
	);
	foreach my $init_obj (@init_list){
		$init_obj->prepareEnvironment($dbh);
		$dbh->commit();
	}
	
	# PW-
	
	my @albums = qw(
		http://cross-land.ru/14 tracksuits
		http://cross-land.ru/39 t-shirts
		http://cross-land.ru/22 clothes_for_men
		http://cross-land.ru/15 accesoires
		http://cross-land.ru/7 Puma
		http://cross-land.ru/19 Nike
		http://cross-land.ru/17 Adidas
		http://cross-land.ru/10 Lacoste
		http://cross-land.ru/18 Converse
		http://cross-land.ru/21 Reebok
		http://cross-land.ru/32 men_women_footwear
		http://cross-land.ru/20 news
		http://cross-land.ru/37 bags
		http://cross-land.ru/41 clothes_for_fitness_yoga
		http://cross-land.ru/40 swimsuit
	);
	
	# at least one object should exist
	check_root($dbh, \@albums);

	# release the handler
	release_dbh($dbh);
	
	# do parsing
	
	# instantiate the ThreadProcessor
	my $tp = get_tp();
	
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
	my ($dbh, $listref) = @_;
	
	while( my $url = shift @$listref ){
		my $name = shift @$listref;
		
		my $obj = Album->new;
		$obj->set('URL', $url);
		$obj->set('Name', $name);
		unless($obj->checkExistence($dbh)){
			$obj->insert($dbh);
		}
		
	}
	
	$dbh->commit();
	
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
