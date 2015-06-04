use strict;
use warnings;



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
use Property;
use Manual;
use ProductPicture;

print "Let's go!\n";

parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
	
		Category->new,
		Product->new,
		
		ProductPicture->new,
		Manual->new,
		
		# ...
	);
	foreach my $init_obj ((@init_list, Property->new)){
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
	
	# use existing list
	# start parsing
	while(1){
		my $stop;
		print "Start reading DB\n";
		my $left = $constants{Parser}{Queue};
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
		
		my ($sec,$min,$hour) = localtime(time);
		print "Time: $hour.$min\n";
		
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
		$root->markDone;
	
		my %used;
		
		my $agent = LWP::UserAgent->new;
		my $resp = $agent->get($constants{Parser}{Root_Category});
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content( $resp->decoded_content() );
		
		my $cats = get_top_categories($tree);
		$tree->delete();
		
		my $href;
		
		foreach my $item (@$cats){
			
			$href = $item->{href};
			next if exists $used{$href};
			$used{$href} = 1;
			
			my $c1 = Category->new;
			$c1->set('Category_ID', $root->ID);
			$c1->set('Name', $item->{name});
			$c1->set('URL', $href);
			$c1->set('Level', 1);
			$c1->markDone if exists $item->{items};
			$c1->insert($dbh);
			if( exists $item->{items} ){
				foreach my $subitem (@{ $item->{items} }){

					$href = $subitem->{href};
					next if exists $used{$href};
					$used{$href} = 1;

					my $c2 = Category->new;
					$c2->set('Category_ID', $c1->ID);
					$c2->set('Name', $subitem->{name});
					$c2->set('URL', $subitem->{href});
					$c2->set('Level', 2);
					$c2->insert($dbh);
				}
			}
		}
		$dbh->commit();
	}
}

sub get_top_categories {
	my $tree = shift;
	
	my @tops = $tree->findnodes( q{//li[@class="Pal1LeftBorder Pal1RightBorder Pal1BG"]} );
	
	my @data;
	
	foreach my $top (@tops){
		
		my $item = {
			name => $top->findvalue( './a' ),
			href => URI->new($top->findvalue( './a/@href' ))->abs('http://www.lightinguniverse.com/')->as_string(),
			items => []
		};
		
		# get subitems
		my @sublist = $top->findnodes( q{./div/a} );
		
		delete $item->{items} if @sublist == 0;
		
		foreach my $sb (@sublist){
			
			# I don't know why, but xpath engine fails here. So I must to use regular expressions
			my $str = $sb->as_HTML('<>&', '', {});
			if( $str =~ /<a href="([^"]+)">([^<]+)<\/a>/ ) #"
			{
				my $name = $2;
				my $href = $1;
				$href=~s/\?.+/?all=1&perPage=200/;
				push @{$item->{items}}, {
					name => $name,
					href => URI->new($href)->abs('http://www.lightinguniverse.com/')->as_string(),
				};
				
			} else {
				die "Bad string $str";
			}
			
		}

		push @data, $item;

	}
	
	return \@data;
}

# creates an instance of the ThreadProcessor class
sub get_tp {
	return new ISoft::ParseEngine::ThreadProcessor(
		dbname=>$constants{Database}{DB_Name},
		dbuser => $constants{Database}{DB_User},
		dbpassword => $constants{Database}{DB_Password},
		dbhost => $constants{Database}{DB_Host},
		cache => 0,
		break_on_fatal => 1,
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
