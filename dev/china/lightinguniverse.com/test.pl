use strict;
use warnings;


use Error ':try';
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use Storable qw(freeze thaw);

# test objects


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;
use ISoft::DB;

use Category;
use Product;


test_cache();


# ----------------------------


sub test_cache {
	my $dbh = get_dbh();
	
	my $prod = Product->new;
	$prod->set('ID', 23945);
	$prod->select($dbh);
	
	my $key = $prod->getMD5();
	print "key is ", $key, "\n";
	
	my ($row) = ISoft::DB::do_query($dbh, sql=>"select * from `cache` where `Key`='$key'");
	release_dbh($dbh);

	my $resp = thaw($row->{Content});
	my $cnt = $resp->content();
	open XX, '>cnt.htm';
	print XX $cnt;
	close XX;

	print $key, "\n";
	
	# get price values
	my $max = 0;
	while($cnt=~/arrOpt\['[\d:]*'\]={price:([\d.]+)/g){
		$max = $1 if $1 > $max;
	}
	
	print "Maximum: $max\n";
	
}

sub test {
	
	my $url = "http://www.store.com/catalogue/"; # the url to be tested
	
	my $debug = 1; # debug mode on
	
	my $dbh = get_dbh() unless $debug;
	
	my $test_obj = new Category(); # or another one...
	$test_obj->set('URL', $url);
	
	# for categories
	#$test_obj->set('Level', 0); # 0 means the Root category
	#$test_obj->set('Page', 1);
	
	
	my $agent = LWP::UserAgent->new;
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


