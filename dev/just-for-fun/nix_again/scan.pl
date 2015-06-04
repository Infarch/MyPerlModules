use strict;
use warnings;

use threads;
use threads::shared;

use Thread::Queue;

use WWW::Mechanize;
use Encode qw(encode_utf8);

our $queue = Thread::Queue->new;

# articles
our @articles = qw ( 92873 97868 95998 97895 86923 68827 93068 90905 76793   90906   56125   54802   67327
77713   42912   80997   30376   46815   98570   98732   97339   97346   80200   68922   91363   76821   91077
68068   98448   92826   91152   90807   71912   85106   91168   91167   31200   36272   50592   87429   50953
76586   91761   59631   91758   89385   33785   92812   36303   84485   96276   95686   92022   44413   27270
70077   90241);

# try lo load all the articles using different agents
our @agents:shared = (
	'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
	'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
	'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
	'Mozilla/5.0 (compatible; Konqueror/3; Linux)'
);

sub get_agent {
	lock @agents;
	my $agent = shift @agents;
	push @agents, $agent;
	return $agent;
}


sub worker {
	
	my $mech = WWW::Mechanize->new(autocheck=> 0);
	
	while ( defined( my $art = $queue->dequeue() ) ){

		$mech->agent( get_agent() );
		$mech->get("http://www.nix.ru/2id.php?aut=0&textfield=$art&min_price=&max_price=&out_of_stock=&fn=");
		my $content = encode_utf8( $mech->content() );
		if( $content =~ /<h1 id='goods_name'>(.*?)<\/h1>/ ){
			print "$1\n\n";
			
			# look for images
			
		} else {
			print "Failed\n\n";
		}	
		
	}
	
}

# build a big queue

foreach (1..100) {
	
	foreach my $art (@articles){
		
		$queue->enqueue("$art");
		
	}
	
}


# start workers

my @workers;
foreach (1..10){
	
	push @workers, threads->new( \&worker );
	
}

# wait for execution

do{
	
	sleep 3;
	
} while ( $queue->pending() );

sleep 30;

foreach (@workers){
	$_->detach();
}

# just one image
# http://www.nix.ru/autocatalog/burocrat/stationery/952_150_3758.html
