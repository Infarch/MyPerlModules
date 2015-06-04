use strict;
use warnings;

use open qw(:std :utf8);

use threads;
use threads::shared;

use Encode 'decode';
use Error qw(:try);
use LWP::Simple 'get';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use URI;

use lib ("/work/perl_lib");
use ISoft::DB;
use DB_Member;






# database connection settings
our $db_name:shared = 'yandex_test';
our $db_user:shared = 'root';
our $db_pass:shared = 'admin';





#our $proxy:shared = '';
our $proxy:shared = '119.70.40.101:8080';
#our $proxy:shared = '58.240.237.32:80';




# for URI corrections
our $site_root:shared = 'http://yaca.yandex.ru';
# for initialization
my $root_category_url = 'http://yaca.yandex.ru/yca/cat/';
my $root_category_name = 'yaca_yandex';

# categories

# returns list of category nodes
our $sc_path:shared = q{//dt[@class='b-rubric__list__item' or @class='b-rubric__list__loopitem']/a[@class='b-rubric__list__item__link']};
# returns category name
our $sc_name:shared = q{.};
# returns category url
our $sc_url:shared = q{./@href};

our $next_page:shared = q{//span[@class='b-pager__active']/a[@class='b-pager__next']/@href};

# products

our $pr_path:shared = q{//li[@class='b-result__item']};

our $pr_name:shared = q{./h3/a[@class='b-result__name'};
our $pr_url:shared = q{./h3/a[@class='b-result__name']/@href};
our $pr_shortdescr:shared = q{.//p[@class='b-result__info']};
our $pr_fulldescr:shared = q{};
our $pr_code:shared = q{};
our $pr_vendor:shared = q{};
our $pr_price:shared = q{.//span[@class='b-result__quote']};




my $thread_limit = 3;




# begin work

my $dbh = get_dbh();
check_first_start($dbh);

print "Before start\n";

start($dbh);
#statistic($dbh);

exit;


# ---------------------------------------------------------------

sub get_tree{
	my ($url) = @_;
	
	my $ua = LWP::UserAgent->new();
	$ua->proxy('http', "http://$proxy") if $proxy;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6');
	my $resp = $ua->get($url);
	
	die "Cannot fetch content of $url\n" unless $resp->is_success();
	
	my $content = $resp->content();
	my $string = '';
	try {
		$string = decode('utf8', $content, Encode::FB_CROAK);
	} otherwise {
		$string = decode('cp1251', $content, Encode::FB_DEFAULT);
	};


	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($string);
	return $tree;
}

sub abs_url{
	my $url = shift;
	return '' unless $url;
	my $uri = URI->new($url);
	return $uri->abs($site_root);
}

sub get_subcategories{
	my ($tree) = @_;
	my @list;
	my @nodes = $tree->findnodes($sc_path);
	foreach my $node (@nodes){
		my %h;
		$h{URL} = abs_url($node->findvalue($sc_url));
		$h{Name} = $node->findvalue($sc_name);
		push @list, \%h;
	}
	return @list;
}

sub process_subcategories{
	my ($dbh, $member_obj, $tree) = @_;
	my @categories = get_subcategories($tree);
	foreach my $category(@categories){
		
		my $xm = DB_Member->new;
		$xm->set('URL', $category->{URL});
		#$xm->set('Type', $DB_Member::TYPE_CATEGORY);
		next if $xm->checkExistence($dbh);
		
		my $new_member_obj = DB_Member->new;
		while (my ($key, $value) = each %$category){
			$new_member_obj->set($key, $value);
		}
		$new_member_obj->set('Member_ID', $member_obj->ID);
		$new_member_obj->set('Type', $DB_Member::TYPE_CATEGORY);
		$new_member_obj->set('Status', $DB_Member::STATUS_READY);
		$new_member_obj->insert($dbh);
	}
	return scalar @categories;
}

sub get_products{
	my ($tree) = @_;
	my @list;
	my @nodes = $tree->findnodes($pr_path);
	foreach my $node (@nodes){
		my %h;
		$h{URL} = abs_url($node->findvalue($pr_url));
		$h{Name} = $node->findvalue($pr_name);
		
		my $tmp = $node->findvalue($pr_price);
		$tmp =~ /(\d+)$/;
		$h{Price} = $1;
		
		$h{ShortDescription} = $node->findvalue($pr_shortdescr);
		push @list, \%h;
	}
	return @list;
}

sub process_products{
	my ($dbh, $member_obj, $tree) = @_;
	my @products = get_products($tree);
	foreach my $product(@products){
		my $new_member_obj = DB_Member->new;

		my $xm = DB_Member->new;
		$xm->set('URL', $product->{URL});
		#$xm->set('Type', $DB_Member::TYPE_PRODUCT);
		next if $xm->checkExistence($dbh);

		while (my ($key, $value) = each %$product){
			$new_member_obj->set($key, $value);
		}
		$new_member_obj->set('Member_ID', $member_obj->ID);
		$new_member_obj->set('Type', $DB_Member::TYPE_PRODUCT);
		$new_member_obj->set('Status', $DB_Member::STATUS_DONE);
		$new_member_obj->insert($dbh);
	}
	return scalar @products;
}

sub get_next_page {
	my $tree = shift;
	my $nextp = $tree->findvalue( $next_page );
	return $nextp ? abs_url($nextp) : '';
}

sub process_category {
	my ($dbh, $member_obj) = @_;
	my $page_number = $member_obj->get('Page');
	my $url = $member_obj->get($page_number==1 ? 'URL' : 'NextURL');
	my $tree = get_tree($url);
	my $global = 0;
	# look for sub categories and products
	if($page_number==1){
		# consider that only the first page contains categories
		$global = process_subcategories($dbh, $member_obj, $tree);
	}
	# we will not search products if there is at least one sub category !!!!!!!!!!!!!!
	if($global==0){
		$global = process_products($dbh, $member_obj, $tree);
		if (my $next_page = get_next_page($tree)){
			$member_obj->set('Page', ++$page_number);
			$member_obj->set('NextURL', $next_page);
			$member_obj->set('Status', $DB_Member::STATUS_READY);
		}
	}
	$tree->delete();
	# no data - error
	die "No data" unless $global;
}

# search duplicate sites
sub process_category_2 {
	my ($dbh, $member_obj) = @_;
	my $page_number = $member_obj->get('Page');
	my $url = $member_obj->get($page_number==1 ? 'URL' : 'NextURL');
	my $tree = get_tree($url);
	
	process_products_2($dbh, $member_obj, $tree);
	if (my $next_page = get_next_page($tree)){
		$member_obj->set('Page', ++$page_number);
		$member_obj->set('NextURL', $next_page);
		$member_obj->set('Status', $DB_Member::STATUS_READY);
	}
		
	$tree->delete();
}

# search duplicate sites
sub process_products_2{
	my ($dbh, $member_obj, $tree) = @_;
	my @products = get_products($tree);
	foreach my $product(@products){

		# this site should NOT be present within the category!
		my $new_member_obj = DB_Member->new;
		$new_member_obj->set('URL', $product->{URL});
		$new_member_obj->set('Member_ID', $member_obj->ID);
		next if $new_member_obj->checkExistence($dbh);
		
		# this site should already be in database!
		$new_member_obj = DB_Member->new;
		$new_member_obj->set('URL', $product->{URL});
		$new_member_obj->set('Member_ID', $member_obj->ID);
		$new_member_obj->setOperator('Member_ID', '!=');
		my @list = $new_member_obj->listSelect($dbh);
		
		next if @list==0;
		$new_member_obj = $list[0];
			
		# insert this site again but using a different category
		$new_member_obj->setAll();
		$new_member_obj->set('Member_ID', $member_obj->ID);
		$new_member_obj->insert($dbh, 1);
		
		print "Added ", $product->{URL}, "\n";
	}

}



sub process_product {
	my ($dbh, $member_obj) = @_;
	
	my $tree;
	my $page = $member_obj->get('Page');
	if($page==1){
		$tree = get_tree($member_obj->URL);
		my $val = $tree->findvalue( q{//title} );
		$member_obj->set('FullDescription', $val);
		$member_obj->set('Page', 2);
		$member_obj->set('Status', $DB_Member::STATUS_READY);
	} elsif($page==2){
		
		# look for the domain creation date
		my $uri = URI->new($member_obj->URL);
		my $host = $uri->host;
		my $query = "http://whois7.ru/?q=$host";
		
		$tree = get_tree($query);
		
		my $text = $tree->findvalue( q{/html/body/div/table/tr/td/div/pre/code} );
		
		if($text=~/created:\s+([\d.]+)/){
			$member_obj->set('Vendor', $1);
		} elsif($text=~/Creation Date: (\d+-\D+-\d+)/){
			$member_obj->set('Vendor', $1);
		} else {
			$member_obj->set('Status', $DB_Member::STATUS_FAILED);
		}
		
	}
	$tree->delete() if defined $tree;
	
}

sub worker {
	my ($member_obj) = shift;
	
	# this status might be changed by another function
	$member_obj->set('Status', $DB_Member::STATUS_DONE);
	
	my $member_id = $member_obj->ID;
	
	my $dbh = get_dbh();
	
	try {
		
		if($member_obj->isCategory()){
			
			#process_category($dbh, $member_obj);
			process_category_2($dbh, $member_obj);
			
			$member_obj->update($dbh);
			
		} elsif($member_obj->isProduct()){
			
			process_product($dbh, $member_obj);
			$member_obj->update($dbh);
			
		} elsif($member_obj->isPicture()){
			die "Is not implemented yet";
		} elsif($member_obj->isFile()){
			die "Is not implemented yet";			
		} else {
			die "Unknown type";
		}
		
		
	} otherwise {
		# discard changes
		print "\nError: $@\n";
		$dbh->rollback();
		
		try {
			
			my $id = $member_obj->ID;
			$member_obj = DB_Member->new;
			$member_obj->set('ID', $id);
			$member_obj->set('Status', $DB_Member::STATUS_PROCESSING);
			$member_obj->select($dbh);
			
			my $errors = $member_obj->get('Errors');
			if($errors++ < 5){
				$member_obj->set('Errors', $errors);
				$member_obj->set('Status', $DB_Member::STATUS_READY);
			} else {
				$member_obj->set('Status', $DB_Member::STATUS_FAILED);
			}
			
			$member_obj->update($dbh);
			
		} otherwise {
			print "Error restoring member: $@";
		};
		
	};
	
	$dbh->commit();
	$dbh->disconnect();
	return $member_id;
	
}

sub start {
	my $dbh = shift;
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
}

#!
sub check_first_start {
	my ($dbh) = @_;
	
	my $member_obj = DB_Member->new;
	$member_obj->set('Member_ID', undef);
	$member_obj->set('Name', $root_category_name);
	$member_obj->set('URL', $root_category_url);
	$member_obj->set('Type', $DB_Member::TYPE_CATEGORY);
	
	my $sr = $DB_Member::STATUS_READY;
	my $sp = $DB_Member::STATUS_PROCESSING;
	
	if($member_obj->checkExistence($dbh)){
		print "Continue work\n";
		my $sql = "update Member set Status=$sr where Status=$sp";
		ISoft::DB::do_query($dbh, sql=>$sql);
	} else {
		print "First start\n";
		$member_obj->set('Status', $DB_Member::STATUS_READY);
		$member_obj->insert($dbh);
	}
	
	$dbh->commit();
}



sub get_dbh {
	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass);
}




# ---------------------------------------------------------------


#!
sub download_file {
	my($folder, $url) = @_;
	
#	$file_sem->down();
	
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
	
#	$file_sem->up();
	
	return $newname;
}


#################################### OTHER FUNCTIONS ######################################

#!
sub get_opened_members {
	my ($dbh, $count) = @_;
	my $member_obj = DB_Member->new;
	$member_obj->set('Status', $DB_Member::STATUS_READY);
	$member_obj->maxReturn($count) if $count;
	my @list = $member_obj->listSelect($dbh);
	
	foreach my $obj(@list){
		$obj->set('Status', $DB_Member::STATUS_PROCESSING);
		$obj->update($dbh);
	}
	
	$dbh->commit();
	
	return @list;
}

#!
sub make_random_name {
	my @c = (0..9,'a'..'z');
	my $pass = Crypt::GeneratePassword::chars(30, 30, \@c);
	return $pass;
}
