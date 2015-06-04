use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use URI;
use LWP::UserAgent;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::ParseEngine::Agents;
use ISoft::ParseEngine::ThreadProcessor;

use ISoft::DBHelper;


# Members
use Category;
use Product;
use Attribute;



parse();


# ----------------------------

sub parse {
	
	# get database handler
	my $dbh = get_dbh();
	
	# prepare environment
	my @init_list = (
		Category->new,
		Product->new,
		Attribute->new
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
		$tp->addAgent("Mozilla/5.0 (Windows NT 6.1; rv:32.0) Gecko/20100101 Firefox/32.0");
	}
	
	
	my @parse_list = (
		Category->new,
		Product->new,
	);

	# start parsing
	while(1){
		my $stop;
		my $left = $constants{Parser}{Queue};
		
		print "Start reading DB...\n";
		
		my $dbhx = get_dbh();
		my @worklist;
		foreach my $workobj(@parse_list){
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
	foreach my $obj (@parse_list){
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
		
		my $url = "http://www.220-volt.ru/catalog/";
		my $agent = LWP::UserAgent->new;
		$agent->agent("Mozilla/5.0 (Windows NT 6.1; rv:32.0) Gecko/20100101 Firefox/32.0");
		my $response = $agent->get($url);
		if ($response->is_success()){
			my $content = $response->decoded_content();
			my $tree = HTML::TreeBuilder::XPath->new;
			$tree->parse_content($response->decoded_content());
			
			my @menu = $tree->findnodes(q{//ul[@class="container-catalog-top cut-lines cut-lines-dark shadow"]/li});
			foreach my $menuitem(@menu){
				my @a = $menuitem->findnodes(q{./a[1]});
				my $category1 = $a[0]->findvalue('.');
				my $ref1 = URI->new($a[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
				
				my $m1_obj = Category->new;
				$m1_obj->set("Category_ID", $root->ID);
				$m1_obj->set("Level", 1);
				$m1_obj->set("Name", $category1);
				$m1_obj->set("URL", $ref1);
				$m1_obj->markDone();
				$m1_obj->insert($dbh);
				
				# whether there are field sets?
				my @sets = $menuitem->findnodes(q{./ul[1]/li[1]/div[@class="fieldset legend-small-position-top"]});
				
				if(@sets){
					# each field set becomes a category
					foreach my $set(@sets){
						my @setnodes = $set->findnodes(q{./div[@class="legend small left top"]/a});
						my $setref = URI->new($setnodes[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
						my $setname = $setnodes[0]->findvalue('.');
						
						my $m2_obj = Category->new;
						$m2_obj->set("Category_ID", $m1_obj->ID);
						$m2_obj->set("Level", 2);
						$m2_obj->set("Name", $setname);
						$m2_obj->set("URL", $setref);
						$m2_obj->markDone();
						$m2_obj->insert($dbh);
						
						my @setmembers = $set->findnodes( q{./div[@class="catalog-item-lev2-group"]} );
						my @setgroups = $setmembers[0]->findnodes( q{.//div[@class="catalog-item-lev2-group"]} );
						
						if(@setgroups){
							# each groups becomes a category,
							# all children belong to the new category.
							
							foreach my $setgroup(@setgroups){
								my @groupdata = $setgroup->findnodes(q{./p[@class="catalog-item-lev2-title"]/a[1]});
								my $groupname = $groupdata[0]->findvalue('.');
								my $groupref = URI->new($groupdata[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
								
								my $parent_obj;
								
								if($groupref eq $setref){
									$parent_obj = $m2_obj;
								} else {
									$parent_obj = Category->new;
									$parent_obj->set("Category_ID", $m2_obj->ID);
									$parent_obj->set("Level", 3);
									$parent_obj->set("Name", $groupname);
									$parent_obj->set("URL", $groupref);
									$parent_obj->markDone();
									$parent_obj->insert($dbh);
								}
								
								# extract members
								my @members = $setgroup->findnodes(q{./ol/li[@class="catalog-item-lev2-unit"]/a});
								
								foreach my $member(@members){
									my $membername = $member->findvalue('.');
									my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
									
									my $mx_obj = Category->new;
									$mx_obj->set("Category_ID", $parent_obj->ID);
									$mx_obj->set("Level", $parent_obj->get("Level")+1);
									$mx_obj->set("Name", $membername);
									$mx_obj->set("URL", $memberref);
									$mx_obj->insert($dbh);
								}
								
							}
							
							
						}else{
							# all children belong to the parent set.
							
								# extract members
								my @members = $set->findnodes(q{.//ol/li[@class="catalog-item-lev2-unit"]/a});
								
								foreach my $member(@members){
									my $membername = $member->findvalue('.');
									my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
									
									my $mx_obj = Category->new;
									$mx_obj->set("Category_ID", $m2_obj->ID);
									$mx_obj->set("Level", $m2_obj->get("Level")+1);
									$mx_obj->set("Name", $membername);
									$mx_obj->set("URL", $memberref);
									$mx_obj->insert($dbh);
								}
						}
						
					}
					
				}else{
					
					my @menu2 = $menuitem->findnodes( q{.//div[@class="catalog-item-lev2-group"]} );
					unless(@menu2){
						# no subcategory groups right here. it is either "spare parts" or "reduced products"
						if($ref1=~/reduced/){
							#print "Reduced objects\n";
						}else{
							my $m2_obj = Category->new;
							$m2_obj->set("Category_ID", $m1_obj->ID);
							$m2_obj->set("Level", 2);
							$m2_obj->set("Name", "Spare parts");
							$m2_obj->set("URL", "http://www.220-volt.ru/catalog/8-0/");
							$m2_obj->insert($dbh);
						}
					}else{
						foreach my $group(@menu2){
							my @groupdata = $group->findnodes(q{./p[@class="catalog-item-lev2-title"]/a[1]});
							my $groupname = $groupdata[0]->findvalue('.');
							my $groupref = URI->new($groupdata[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
							
							my $parent_obj;
							if($groupref eq $ref1){
								$parent_obj = $m1_obj;
							}else{
								$parent_obj = Category->new;
								$parent_obj->set("Category_ID", $m1_obj->ID);
								$parent_obj->set("Level", 2);
								$parent_obj->set("Name", $groupname);
								$parent_obj->set("URL", $groupref);
								$parent_obj->markDone();
								$parent_obj->insert($dbh);
								
							}
	
							my @members = $group->findnodes(q{.//ol/li[@class="catalog-item-lev2-unit"]/a});
							
							foreach my $member(@members){
								my $membername = $member->findvalue('.');
								my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
								
								my $mx_obj = Category->new;
								$mx_obj->set("Category_ID", $parent_obj->ID);
								$mx_obj->set("Level", $parent_obj->get("Level")+1);
								$mx_obj->set("Name", $membername);
								$mx_obj->set("URL", $memberref);
								$mx_obj->insert($dbh);
							}
						}
						
					}
					
				}
				
			}
			
			
			$tree->delete();
		}else{
			die "FAILED!!!";
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
