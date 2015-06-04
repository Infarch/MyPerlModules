use strict;
use warnings;

use utf8;

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
	release_dbh($dbh);
	
	# do parsing
	
	# instantiate the ThreadProcessor
	my $use_cache = 1; #0
	my $tp = get_tp($use_cache);
	
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
			my @tmp = $workobj->getWorkList($dbhx, $limit);
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
	$root->markDone();
	unless($root->checkExistence($dbh)){
		$root->insert($dbh);
		
		# categories to be parsed
		my @cats = (
			'http://www.ru.all.biz/stroitelnaya-tehnika-bgm270?b2b', 'Строительная техника',
			'http://www.ru.all.biz/strojmaterialy-bgm280?b2b',  'Стройматериалы',
			'http://www.ru.all.biz/derevo-pilomaterialy-bgm60?b2b ', 'Дерево, пиломатериалы'
		);
		
		while(my $url = shift @cats){
			my $c = Category->new;
			$c->set('Category_ID', $root->ID);
			$c->set('URL', $url);
			$c->set("Name", shift @cats);
			$c->set('Level', 1);
			$c->insert($dbh);
		}
		
		$dbh->commit();
	}
	
}

# creates an instance of the ThreadProcessor class
sub get_tp {
	my $cache = shift;
	return new ISoft::ParseEngine::ThreadProcessor(
		dbname=>$constants{Database}{DB_Name},
		dbuser => $constants{Database}{DB_User},
		dbpassword => $constants{Database}{DB_Password},
		dbhost => $constants{Database}{DB_Host},
		cache => $cache
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
