use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use threads;


use Error qw(:try);
use DBI;
use WWW::Mechanize;
use Crypt::GeneratePassword;
use Image::Resize;
use Thread::Semaphore;

use lib ("/work/perl_lib");
use ISoft::DB;
use DB_Member;

our $file_sem = Thread::Semaphore->new(1);

my $root_url = 'http://printsip.ru/cgi/shop';
my $root_category = 'printsip_root';

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
		
		my $content = pretty_content(safe_get($member_obj->get('URL')));
		
		my $page_number = $member_obj->get('Page');
		
		if($page_number==1){
			# consider that only the first page contains categories
			my @categories = get_categories($content);
			if (@categories > 0){
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
		}
		
		my @products = get_products($content);
		if (@products > 0){
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
		} 
		
		if(my $next_page = get_next_page($content)){
			$member_obj->set('URL', $next_page);
			$member_obj->set('Page', $page_number+1);
			$member_obj->set('Status', $DB_Member::STATUS_READY);
		} else {
			$member_obj->set('Status', $DB_Member::STATUS_DONE);
		}
		
		$member_obj->update($dbh);
		
	} elsif ( $member_obj->isProduct ) {

		# download product data
		my $content = pretty_content(safe_get($member_obj->get('URL')));
		
		my $product_info = get_product_info($content);
		while (my ($key, $value) = each %$product_info){
			$member_obj->set($key, $value);
		}
		$member_obj->set('Status', $DB_Member::STATUS_DONE);
		$member_obj->update($dbh);
		
		if ( my $pic_url = get_product_picture_url($content) ){
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
		
		print "Loading picture\n";
		
		if( my $pic_name = download_file('images/printsip', $member_obj->get('URL')) ){
			$member_obj->set('Name', $pic_name);
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
		open XX, ">$folder/$newname";
		binmode XX;
		print XX $content;
		close XX;
		
	} else {
		#die "Bad file url!";
	}
	
	$file_sem->up();
	
	return $newname;
}

#!
sub get_product_picture_url {
	my $content = shift;
	my $url = '';
	if ($content =~ /<div class="itemimagedescription"><a href="([^"]+)"/)#"
	{
		$url = "http://printsip.ru$1";
	}
	return $url;
}

#!
sub get_product_info {
	my $content = shift;
	
	my $price = '0';
	if($content =~ /<div class="pricename">[^<]+<\/div><div class="(?!availability)[^"]+">[^<]+<span>([^<]+)<\/span>/)#"
	{
		$price = $1;
		$price =~ s/&nbsp;//g;
	}
	
	my $description = '';
	if($content =~ /<div class="itemfullspecpanel">(.*?)<\/div><\/div><\/td><td class="r">/){
		$description = $1;
	}
	
	my $iid = '';
	if($content =~ /<div class="buy"><a href="\/cgi\/shop\/basketadd\?item=(\d+)"/){
		$iid = $1;
	}
	
	return {
		Price => $price,
		FullDescription => $description,
		InternalID => $iid
	};
	
}

#!
sub get_products {
	my ($content) = @_;
	my @list;
	
	while($content =~ /<div\sclass="shortname"><a\shref="([^"]+)"\stitle="[^"]+">([^<]+)<\/a><\/div>
	<div\sclass="shortdescr">(.*?)<\/div>
	<div\sclass="vendor">[^<]+<\/div>
	<div\sclass="vendorval">(<img\ssrc="[^"]+"\swidth="20"\sheight="13"\salt="[^"]+">\s|)([^<]+)<\/div><\/td><td\sclass="itemprice">/xg)#"
	{
		push @list, {
			URL => "http://printsip.ru$1",
			Name => $2,
			ShortDescription => $3,
			Vendor => $5
		}
	}
	
	return @list;
}

#!
sub get_next_page {
	my $content = shift;
	my $np = '';
	if( $content =~ /<span class="a">\d+<\/span>\s<span><a href="([^"]+)">\d+<\/a><\/span>/ ) #"
	{
		$np = "http://printsip.ru$1";
	}
	return $np;
}

#!
sub get_categories {
	my ($content) = @_;
	my @list;
	while($content =~ /<div class="group"><a href="([^"]+)">([^<]+)<\/a> \((\d+)\)<\/div>/g)#"
	{
		push @list, {
			URL => "http://printsip.ru$1",
			Name => $2
		}
	}
	return @list;
}


#################################### OTHER FUNCTIONS ######################################

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
		$member_obj->set('Status', $DB_Member::STATUS_READY);
		$member_obj->insert($dbh);
	}
	
	$dbh->commit();
}

#!
sub pretty_content {
	my $content = shift;
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	return $content;
}

#!
sub safe_get {
	my $url = shift;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	while (!$mech->get($url)){
		print "Error getting $url\n";
		sleep 1;
	}
	return $mech->content();
}

#!
sub get_dbh {
	return ISoft::DB::get_dbh_mysql('printsip', 'root', 'admin');
}

#!
sub make_random_name {
	my @c = (0..9,'a'..'z');
	my $pass = Crypt::GeneratePassword::chars(30, 30, \@c);
	return $pass;
}
