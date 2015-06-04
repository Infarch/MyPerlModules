use strict;
use warnings;
use utf8;
#use open qw(:std :utf8);

use threads;
use threads::shared;

use Error qw(:try);
use DBI;
use WWW::Mechanize;
use Thread::Semaphore;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib");
use ISoft::DB;
use DB_Member;

our $file_sem = Thread::Semaphore->new(1);

my $root_url = 'http://www.fluke-russia.ru/';
my $root_category = 'fluke_root';

my $thread_limit = 15;

my $status_done = $DB_Member::STATUS_DONE;
my $status_ready = $DB_Member::STATUS_READY;
my $status_processing = $DB_Member::STATUS_PROCESSING;


# begin work

my $dbh = get_dbh();




check_first_start($dbh);




# start all possible workers first
foreach my $member_obj ( get_opened_members($dbh, $thread_limit) ){
	my $xx = threads->create( 'worker', $member_obj );
}

do {
	
	# get joinable threads
	my @joinable_list = threads->list(threads::joinable);
	my $jcount = @joinable_list;
	# join and save data
	foreach my $thread (@joinable_list){
		my $obj = $thread->join();
		#$obj->update($dbh);
		#$dbh->commit;
	}	

	if($jcount){
		print "Joined $jcount threads\n";
		foreach my $member_obj ( get_opened_members($dbh, $jcount) ){
			my $xx = threads->create( 'worker', $member_obj );
		}
	}
	
} while (threads->list() > 0);






exit;





my $category_limit;
my $type_categories;
my $type_companies;








##################################### WORKERS #############################################

sub worker {
	my ($member_obj) = shift;
	
	my $member_id = $member_obj->ID;
	
	my $dbh = get_dbh();
	
	if ( $member_obj->isCategory ) {
		
		# look for sub categories and products
		
		my $content = safe_get($member_obj->get('URL'));
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($content);
		
		my $page_number = $member_obj->get('Page');
		
		if($page_number==1){
			# consider that only the first page contains categories
			my @categories = get_categories($tree);
			foreach my $category(@categories){
				my $new_member_obj = DB_Member->new;
				while (my ($key, $value) = each %$category){
					$new_member_obj->set($key, $value);
				}
				$new_member_obj->set('Member_ID', $member_id);
				$new_member_obj->set('Type', $DB_Member::TYPE_CATEGORY);
				$new_member_obj->set('Status', $DB_Member::STATUS_READY);
				$new_member_obj->insert($dbh);
			}
		}
		
		my @products = get_products($tree);
		foreach my $product(@products){
			my $new_member_obj = DB_Member->new;
			while (my ($key, $value) = each %$product){
				$new_member_obj->set($key, $value);
			}
			$new_member_obj->set('Member_ID', $member_id);
			$new_member_obj->set('Type', $DB_Member::TYPE_PRODUCT);
			$new_member_obj->set('Status', $DB_Member::STATUS_READY);
			$new_member_obj->insert($dbh);
		}
		
		if(my $next_page = get_next_page($tree)){
			$member_obj->set('URL', $next_page);
			$member_obj->set('Page', $page_number+1);
			$member_obj->set('Status', $DB_Member::STATUS_READY);
		} else {
			$member_obj->set('Status', $DB_Member::STATUS_DONE);
		}
		
		$member_obj->update($dbh);
		
	} elsif ( $member_obj->isProduct ) {

		# download product data
		my $content = safe_get($member_obj->get('URL'));
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($content);
		
		$member_obj->set('Price', 0);
		$member_obj->set('Name', $tree->findvalue( q{/html/body/div[2]/div[9]/table/tr/td[2]/div[3]/div[1]/a} ));
		
		#my @nodelist = $tree->findnodes( q{/html/body/div[2]/div[9]/table/tr/td[2]/div[4]} );
		my @nodelist = $tree->findnodes( q{//div[@class='main_text']} );
		if(@nodelist==1){
			my $description_node = $nodelist[0];
			
			my @picnodes = $tree->findnodes( q{//div[@class='main_text']//img} );
			
			foreach my $node (@picnodes){
				
				my $pic_url = $node->attr('src');
				
				my $pic_member_obj = DB_Member->new;
				$pic_member_obj->set('Name', '');
				$pic_member_obj->set('Member_ID', $member_id);
				$pic_member_obj->set('URL', "http://www.fluke-russia.ru/$pic_url");
				$pic_member_obj->set('Type', $DB_Member::TYPE_FILE);
				$pic_member_obj->set('Status', $DB_Member::STATUS_READY);
				$pic_member_obj->insert($dbh);
				
				$node->attr('member', $pic_member_obj->ID);
			}
		
			$member_obj->set('FullDescription', $description_node->as_HTML('<>&'));
		}
		
		$member_obj->set('Status', $DB_Member::STATUS_DONE);
		$member_obj->update($dbh);
		
		if ( my $pic_url = get_product_picture_url($tree) ){
			my $pic_member_obj = DB_Member->new;
			$pic_member_obj->set('Name', '');
			$pic_member_obj->set('Member_ID', $member_id);
			$pic_member_obj->set('URL', $pic_url);
			$pic_member_obj->set('Type', $DB_Member::TYPE_PICTURE);
			$pic_member_obj->set('Status', $DB_Member::STATUS_READY);
			$pic_member_obj->insert($dbh);
		}
		
		
		$member_obj->update($dbh);
		
	} elsif ( $member_obj->isPicture ) {
		# download picture
		
		if( my $pic_name = download_file('images/fluke', $member_obj->get('URL')) ){
			$member_obj->set('Name', $pic_name);
			$member_obj->set('Status', $DB_Member::STATUS_DONE);
			$member_obj->update($dbh);
		} else {
			# bad picture, delete
			$member_obj->delete($dbh);
		}
		
		
	} elsif ( $member_obj->isFile ) {
		# in this section we will process pictures placed within product descriptions
		
		if( my $pic_name = download_file('images/userfiles', $member_obj->get('URL')) ){
			$member_obj->set('Name', $pic_name);
			$member_obj->set('Status', $DB_Member::STATUS_DONE);
			$member_obj->update($dbh);
		} else {
			# bad picture, delete
			$member_obj->delete($dbh);
		}
			
	}	else {
		print "Bad member type!!!\n";
	}
	
	
	$dbh->commit();
	
}


##################################### PARSERS #############################################

#!
sub get_product_picture_url {
	my $tree = shift;
	
	my $url = '';
	if($url = $tree->findvalue( q{/html/body/div[2]/div[9]/table/tr/td[2]/div[3]/div[2]/div/center/img/@src} ) ){
		$url = "http://www.fluke-russia.ru/$url";
	}
	
	return $url;
}

#!
sub get_product_info {
	my $tree = shift;
	
	my $price = 0;
	
	my $product_title = $tree->findvalue( q{/html/body/div[2]/div[9]/table/tr/td[2]/div[3]/div[1]/a} );
	
	my @nodelist = $tree->findnodes( q{/html/body/div[2]/div[9]/table/tr/td[2]/div[4]} );
	my $descr = '';
	if (@nodelist==1){
		$descr = $nodelist[0]->as_HTML('<>&');
	}
	
	return {
		Price => $price,
		Name => $product_title,
		FullDescription => $descr,
	};
	
}

#!
sub get_products {
	my ($content) = @_;
	my @list;
	
	# does not make sense - we already have all products on the main page
	
#	while($content =~ /<div\sclass="shortname"><a\shref="([^"]+)"\stitle="[^"]+">([^<]+)<\/a><\/div>
#	<div\sclass="shortdescr">(.*?)<\/div>
#	<div\sclass="vendor">[^<]+<\/div>
#	<div\sclass="vendorval">(<img\ssrc="[^"]+"\swidth="20"\sheight="13"\salt="[^"]+">\s|)([^<]+)<\/div><\/td><td\sclass="itemprice">/xg)#"
#	{
#		push @list, {
#			URL => "http://printsip.ru$1",
#			Name => $2,
#			ShortDescription => $3,
#			Vendor => $5
#		}
#	}
	
	return @list;
}

#!
sub get_next_page {
	my $content = shift;
	my $np = '';
	
	# does not make sense - we don't have any multi-page category
	
#	if( $content =~ /<span class="a">\d+<\/span>\s<span><a href="([^"]+)">\d+<\/a><\/span>/ ) #"
#	{
#		$np = "http://printsip.ru$1";
#	}
	return $np;
}

#!
sub get_categories {
	my ($content) = @_;
	my @list;
	
	# does not make sense - we already have all categories on the main page
	
#	while($content =~ /<div class="group"><a href="([^"]+)">([^<]+)<\/a> \((\d+)\)<\/div>/g)#"
#	{
#		push @list, {
#			URL => "http://printsip.ru$1",
#			Name => $2
#		}
#	}
	return @list;
}


#################################### OTHER FUNCTIONS ######################################

#!
sub download_file {
	my($folder, $url) = @_;
	$file_sem->down();
	my $name = '';
	my $ext = '';
	my $newname = '';
	# check name
	if ($url =~ /\/([^\/]+)$/){
		$newname = $1;
		if ( $newname =~ /^(.+?)\.([^.]+)$/ ){
			$name = $1;
			$ext = ".$2";
		} else {
			$name = $newname;
		}
		my $counter = 2;
		while(-e "$folder/$newname" && -f "$folder/$newname"){
			$newname = "$name($counter)$ext";
			$counter++;
		}
		my $content = safe_get($url);
		if($content){
			open XX, ">$folder/$newname";
			binmode XX;
			print XX $content;
			close XX;
		} else {
			$newname = '';
		}
	} else {
		#die "Bad file url!";
	}
	$file_sem->up();
	return $newname;
}

#!
sub get_opened_members {
	my ($dbh, $count) = @_;
	my $member_obj = DB_Member->new;
	$member_obj->set('Status', $status_ready);
	$member_obj->maxReturn($count) if $count;
	my @list = $member_obj->listSelect($dbh);
	
	foreach my $obj(@list){
		$obj->set('Status', $status_processing);
		$obj->update($dbh);
	}
	
	$dbh->commit();
	
	return @list;
}

#!
sub check_first_start {
	my ($dbh) = @_;
	
	my $member_obj = DB_Member->new;
	$member_obj->set('Member_ID', undef);
	$member_obj->set('Name', $root_category);
	$member_obj->set('URL', $root_url);
	$member_obj->set('Type', $DB_Member::TYPE_CATEGORY);
	
	if($member_obj->checkExistence($dbh)){
		print "Continue work\n";
		my $sql = "update Member set Status=$status_ready where Status=$status_processing";
		ISoft::DB::do_query($dbh, sql=>$sql);
	} else {
		print "First start\n";
		$member_obj->set('Status', $DB_Member::STATUS_DONE);
		$member_obj->insert($dbh);
		
		# read categories and products
		print "Reading main page...\n";
		
		my $doc = HTML::TreeBuilder::XPath->new();
		$doc->parse_content(safe_get($root_url));
		
		my @categories = $doc->findnodes(q{/html/body/div[@align='center']/div/table/tr[1]/td[2]/table/tr/td/div[@style]});
		foreach my $category (@categories){
			
			my $category_title = $category->findvalue( q{div[1]/a} );
			my $category_url = $category->findvalue( q{div[1]/a/@href} );
			
			my $catmember_obj = DB_Member->new;
			$catmember_obj->set('Name', $category_title);
			$catmember_obj->set('URL', "$root_url$category_url");
			$catmember_obj->set('Type', $DB_Member::TYPE_CATEGORY);
			$catmember_obj->set('Status', $DB_Member::STATUS_DONE);
			$catmember_obj->set('Member_ID', $member_obj->ID);
			$catmember_obj->insert($dbh);
			
			my @products = $category->findnodes( q{div[2]/a} );
			
			foreach my $product (@products){
				
				my $product_url = $product->findvalue( q{@href} );
				my $product_short_name = $product->as_text(  );
				
				my $prodmember_obj = DB_Member->new;
				$prodmember_obj->set('Member_ID', $catmember_obj->ID);
				$prodmember_obj->set('InternalID', $product_short_name);
				$prodmember_obj->set('URL', "$root_url$product_url");
				$prodmember_obj->set('Name', '');
				$prodmember_obj->set('Vendor', 'Fluke');
				$prodmember_obj->set('Type', $DB_Member::TYPE_PRODUCT);
				$prodmember_obj->set('Status', $DB_Member::STATUS_READY);
				$prodmember_obj->insert($dbh);
				
			}
			
		}
		print "Done. Starting work.\n";
	}
	
	$dbh->commit();
}

#!
sub safe_get {
	my $url = shift;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	while (!$mech->get($url)){
		print "Error getting $url\n";
		sleep 1;
	}
	if($mech->status()==200){
		return $mech->content();
	} else {
		return '';
	}
	
}

#!
sub get_dbh {
	return ISoft::DB::get_dbh_mysql('fluke', 'root', 'admin');
}

