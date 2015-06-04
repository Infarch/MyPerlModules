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
use Manual;



parse();

exit;

# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
	
		Category->new,
		Manual->new,
		
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
	unless($root->checkExistence($dbh)){
		$root->markDone();
		$root->insert($dbh);
		
		# read categories from the main page
		my $agent = LWP::UserAgent->new;
		my $response = $agent->get($constants{Parser}{Root_Category});
		die "failed" unless $response->is_success();
		
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($response->decoded_content);
		
		# get suitable elements
		my @elements = $tree->findnodes( q{.//*[@id='maincol']/h2/span | .//*[@id='maincol']/div/table/tr/td/ul/li/a} );
		
		my $owner;
		my $c = 0;
		foreach my $element (@elements){
			
			if( $element->tag eq 'span' ){
				# top element
				my $name = $element->findvalue('.');
				$owner = Category->new;
				$owner->set('Category_ID', $root->ID);
				$owner->set('Name', $name);
				$owner->markDone();
				$owner->set('Level', 1);
				$owner->set('URL', $constants{Parser}{Root_Category} . $c++);
				$owner->insert($dbh);
				
			} else {
				# child element
				my $name = $element->findvalue('.');
				my $href = $element->findvalue('./@href');
				
				my $child = Category->new();
				$child->set('Category_ID', $owner->ID);
				$child->set('Name', $name);
				$child->set('URL', $owner->absoluteUrl($href));
				$child->set('Level', 2);
				$child->insert($dbh);
			}
			
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
