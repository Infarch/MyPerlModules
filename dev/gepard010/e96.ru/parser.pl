use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;
use URI;



use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::ParseEngine::Agents;
use ISoft::ParseEngine::ThreadProcessor;

use ISoft::DBHelper;


# Members
use Category;
use Product;
use ProductPicture;
use ProductDescriptionPicture;

use Property;

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
		ProductDescriptionPicture->new,
		
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
		$root->markDone;
		$root->insert($dbh);
		
		# read the first page and insert 1 and 2 level sub categories
		my $sub_list = get_subcategories();
		
		foreach my $item (@$sub_list){
			
			my $c1 = Category->new;
			$c1->set('Category_ID', $root->ID);
			$c1->set('Name', $item->{name});
			$c1->set('URL', $root->absoluteUrl($item->{href}));
			$c1->set('Level', 1);
			$c1->markDone if exists $item->{items};
			$c1->insert($dbh);
			
			if( exists $item->{items} ){
				
				foreach my $subitem (@{ $item->{items} }){
					
					my $c2 = Category->new;
					$c2->set('Category_ID', $c1->ID);
					$c2->set('Name', $subitem->{name});
					$c2->set('URL', $c1->absoluteUrl($subitem->{href}));
					$c2->set('Level', 2);
					$c2->insert($dbh);
					
				}
				
			}
			
		}
		
		$dbh->commit();
	}
	
}

sub get_subcategories {
	
	my $agent = LWP::UserAgent->new;
	my $resp = $agent->get('http://e96.ru/');
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($resp->decoded_content());
	
	my @data;
	
	my @nodes = $tree->findnodes( q{//div[@class="icat"]} );
	foreach my $node (@nodes){
		
		# name
		my $top_name = $node->findvalue( q{./div[@class="icat1"]} );
		
		# check sub items
		my @subnodes = $node->findnodes( q{./div[@class="icat2"]/div[@class="icat3"]/a} );
		
		next if @subnodes == 0; # not a real list
		
		# construct a virtual url
		my $example = $subnodes[0]->findvalue('./@href');
		$example =~ /^\/catalog\/(.+?)\//;

		my $item = {
			name => $top_name,
			href => URI->new("/catalog/$1/")->abs('http://e96.ru/')->as_string()
		};

		my @sublist;
		
		foreach my $sn (@subnodes){
			my $sub_name = $sn->findvalue( q{.} );
			my $sub_href = $sn->findvalue( q{./@href} );
			push @sublist, {
				name => $sub_name,
				href => $sub_href
			};
		}
		
		$item->{items} = \@sublist;
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
		
		break_on_fatal => 0,
		
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
