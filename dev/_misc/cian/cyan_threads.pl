use strict;
use warnings;

use threads;

use WWW::Mechanize;



my @links = (
	'http://www.cian.ru/cat.php?type=4&currency=2&obl_id=1&p=[1-$N1]&order=4',
	'http://www.cian.ru/cat.php?offices=yes&deal_type=1&type=1&price_type=1&currency=2&obl_id=1&p=[1-$N2]&order=4',
	'http://www.cian.ru/cat.php?deal_type=2&type=1&currency=2&obl_id=1&p=[1-$N3]&order=4',
	'http://www.cian.ru/cat.php?suburbian=yes&deal_type=2&type=1&currency=2&obl_id=1&p=[1-$N4]&order=4',
	'http://www.cian.ru/cat.php?offices=yes&deal_type=2&type=1&price_type=1&currency=2&obl_id=1&p=[1-$N5]&order=4'
);


my $dc = 0;
foreach my $link (@links){

	my $folder = 'cyan_' . ++$dc;
	mkdir $folder;
	unlink glob "$folder/*";
	
	die "Cannot create a thread" unless 
		defined threads->create( 'worker', $link, $folder );
		
	sleep 20;
}

while ($dc){
	sleep 10;
	
	my @joinable = threads->list(threads::joinable);
	foreach my $thrd (@joinable){
		$thrd->join();
		$dc--;
	}
	
	print "\nYou have $dc threads working right now\n\n";
	
}


print "\n\nDone\n";

exit;



sub worker {
	my ($link, $folder) = @_;
	
	my $mech = WWW::Mechanize->new;

	my $fc = 1;
	do {
		$mech->get($link);
		print $mech->uri()->as_string(), "\n";
		
		my $content = $mech->response()->decoded_content();
		# store the content into a file
		open XX, '>:encoding(UTF-8)', "$folder/cyan_$fc.htm";
		$fc++;
		print XX $content;
		close XX;
		# look for the next page
		if($content=~/<b style="color: white; background-color: #659AB1;">&nbsp;\d+&nbsp;&nbsp;<\/b> \| <a rel="nofollow" href="(.*?)">\d+<\/a>/){
			$link = $1;
		} else {
			$link = '';
		}
		
		threads->yield();
		
	} while ($link);
	
}
