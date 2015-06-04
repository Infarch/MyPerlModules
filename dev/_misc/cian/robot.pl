use strict;
use warnings;

use LWP::RobotUA;
use URI;


my @links = (
	'http://www.cian.ru/cat.php?type=4&currency=2&obl_id=1&p=[1-$N1]&order=4',
	'http://www.cian.ru/cat.php?offices=yes&deal_type=1&type=1&price_type=1&currency=2&obl_id=1&p=[1-$N2]&order=4',
	'http://www.cian.ru/cat.php?deal_type=2&type=1&currency=2&obl_id=1&p=[1-$N3]&order=4',
	'http://www.cian.ru/cat.php?suburbian=yes&deal_type=2&type=1&currency=2&obl_id=1&p=[1-$N4]&order=4',
	'http://www.cian.ru/cat.php?offices=yes&deal_type=2&type=1&price_type=1&currency=2&obl_id=1&p=[1-$N5]&order=4'
);

# init user agent, setup variables
my $agent = LWP::RobotUA->new('my-robot/0.1', 'me@foo.com');
$agent->delay(1/60);

my $prev_url = '';
my $total_counter = 0;

# directory counter
my $dc = 1;

foreach my $link (@links){
	
	print "\nStrating explore :\n$link\n\n";
	
	my $folder = 'cian_' . $dc++;
	
	print "Wiping target folder $folder\n";
	
	mkdir $folder;
	unlink glob "$folder/*";
	
	# first open the start page
	request('http://www.cian.ru/');
	
	my $fc = 1;
	do {
		my $content = request($link)->decoded_content();
		# store the content into a file
		open XX, '>:encoding(UTF-8)', "$folder/cian_$fc.htm";
		$fc++;
		print XX $content;
		close XX;
		# look for the next page
		if($content=~/<b style="color: white; background-color: #659AB1;">&nbsp;\d+&nbsp;&nbsp;<\/b> \| <a rel="nofollow" href="(.*?)">\d+<\/a>/){
			$link = URI->new($1)->abs($link)->as_string;
		} else {
			$link = '';
		}
		
	} while ($link);
	
}

print "Done\n";
exit;

# the function performs all requests
sub request {
	my($url) = @_;
	
	my $try_count = 5;
	my $response;
	
	# debug echo
	print "$url\n";
	
	my $ok;
	do {
		$response = $agent->get($url);
		$ok = $response->is_success();
		if(!$ok){
			print "Request failed, try again\n";
			sleep 2;
		}
	} while (!$ok && $try_count--);
	
	if(!$response->is_success()){
		die "Connection error";
	}
	
	return $response;
}
