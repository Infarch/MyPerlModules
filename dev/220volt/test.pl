use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode 'encode';
use URI;

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;

use Category;
use Product;

# http://www.220-volt.ru/catalog-118105/
# has many properties

# http://www.220-volt.ru/catalog-14936/crumpled/
# out of stock


test();


# ----------------------------
sub parse {
	my $url = "http://www.220-volt.ru/catalog/";
	my $agent = LWP::UserAgent->new;
	$agent->agent("Mozilla/5.0 (Windows NT 6.1; rv:32.0) Gecko/20100101 Firefox/32.0");
	my $response = $agent->get($url);
	if ($response->is_success()){
		my $content = $response->decoded_content();
		#open XX, ">test.txt";
		#print XX $content;
		#close XX;
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($response->decoded_content());
		
		my @menu = $tree->findnodes(q{//ul[@class="container-catalog-top cut-lines cut-lines-dark shadow"]/li});
		foreach my $menuitem(@menu){
			my @a = $menuitem->findnodes(q{./a[1]});
			my $category1 = $a[0]->findvalue('.');
			my $ref1 = URI->new($a[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
			
			print encode('cp866', $category1), " $ref1\n";
			
			# whether there are field sets?
			my @sets = $menuitem->findnodes(q{./ul[1]/li[1]/div[@class="fieldset legend-small-position-top"]});
			
			if(@sets){
				# each field set becomes a category
				foreach my $set(@sets){
					my @setnodes = $set->findnodes(q{./div[@class="legend small left top"]/a});
					my $setref = URI->new($setnodes[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
					my $setname = $setnodes[0]->findvalue('.');
					
					print "SET : ", encode('cp866', $setname), " $setref\n";
					
					my @setmembers = $set->findnodes( q{./div[@class="catalog-item-lev2-group"]} );
					my @setgroups = $setmembers[0]->findnodes( q{.//div[@class="catalog-item-lev2-group"]} );
					
					if(@setgroups){
						# each groups becomes a category,
						# all children belong to the new category.
						
						foreach my $setgroup(@setgroups){
							my @groupdata = $setgroup->findnodes(q{./p[@class="catalog-item-lev2-title"]/a[1]});
							my $groupname = $groupdata[0]->findvalue('.');
							my $groupref = URI->new($groupdata[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
							
							print "GROUP : ", encode('cp866', $groupname), " $groupref\n";
							
							if($groupref eq $setref){
								print "* actually, the group is the parent set\n";
							}
							
							# extract members
							my @members = $setgroup->findnodes(q{./ol/li[@class="catalog-item-lev2-unit"]/a});
							
							foreach my $member(@members){
								my $membername = $member->findvalue('.');
								my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
								
								print "MEMBER : ", encode('cp866', $membername), " $memberref\n";
							}
							
						}
						
						
					}else{
						# all children be`long to the parent set.
						
							# extract members
							my @members = $set->findnodes(q{.//ol/li[@class="catalog-item-lev2-unit"]/a});
							
							foreach my $member(@members){
								my $membername = $member->findvalue('.');
								my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
								
								print "MEMBER : ", encode('cp866', $membername), " $memberref\n";
							}
					}
					
					#my $dbh = my $category_obj = undef;
					#extract_groups($dbh, $menu2[0], $category_obj);
					
				}
				
				
			}else{
				
				my @menu2 = $menuitem->findnodes( q{.//div[@class="catalog-item-lev2-group"]} );
				unless(@menu2){
					# no subcategory groups right here. it is either "spare parts" or "reduced products"
					if($ref1=~/reduced/){
						print "Reduced objects\n";
					}
				}else{
					foreach my $group(@menu2){
						my @groupdata = $group->findnodes(q{./p[@class="catalog-item-lev2-title"]/a[1]});
						my $groupname = $groupdata[0]->findvalue('.');
						my $groupref = URI->new($groupdata[0]->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
						print "xGROUP : ", encode('cp866', $groupname), " $groupref\n";
						if($groupref eq $ref1){
							print "* actually, the group is the parent menu item\n";
						}

						my @members = $group->findnodes(q{.//ol/li[@class="catalog-item-lev2-unit"]/a});
						
						foreach my $member(@members){
							my $membername = $member->findvalue('.');
							my $memberref = URI->new($member->findvalue('./@href'))->abs("http://www.220-volt.ru/catalog/")->as_string;
							
							print "MEMBER : ", encode('cp866', $membername), " $memberref\n";
						}
					}
					
				}
				
			}
			
		}
		
		
		$tree->delete();
	}else{
		print "FAILED!!!\n";
	}
	
	
}

sub test {
	
	my $url = "http://www.220-volt.ru/catalog/smesiteli/510/";
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Category(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	$test_obj->set('Level', 0); # 0 means the Root category
	$test_obj->set('Page', 1);
	
	
	my $agent = LWP::UserAgent->new;
	$agent->agent("Mozilla/5.0 (Windows NT 6.1; rv:32.0) Gecko/20100101 Firefox/32.0");
	my $request = $test_obj->getRequest();
	my $response = $agent->request($request);
	if ($response->is_success()){
		try {
			$test_obj->processResponse($dbh, $response, $debug);
		} catch ISoft::Exception with {
			print "Error: ", $@->message(), "\n", $@->trace();
		};
	}
	
	if(defined $dbh){
		$dbh->release_dbh(); # or commit
	}
	
}


