use strict;
use warnings;

use threads;
use threads::shared;


use Thread::Queue;
use WWW::Mechanize;
use URI;


use SimpleConfig;
use Utils;

our $taskqueue = Thread::Queue->new;
our $matchqueue = Thread::Queue->new;
our $dontmatchqueue = Thread::Queue->new;
our $failqueue = Thread::Queue->new;


our $maxouters = $constants{UrlChecker}{MaxOuters};

# load data, populate the task queue
my @url_list;
Utils::load_lines($constants{UrlChecker}{Source}, \@url_list);

foreach (@url_list){
	$taskqueue->enqueue($_);
	
	last;
	
}

# start threads
foreach (1..3){
	threads->create('worker');
}

# wait for finish
my @running;
do{
	sleep 10;
	my @joinable = threads->list(threads::joinable);
	foreach (@joinable){
		$_->join();
	}
	@running = threads->list(threads::running);
} while ( @running > 0 );

# save data:

# 1. match
queue2file($matchqueue, $constants{UrlChecker}{Matches});
# 2. dont match
queue2file($dontmatchqueue, $constants{UrlChecker}{Others});
# 3. fails
queue2file($failqueue, $constants{UrlChecker}{Failed});


print "Done\n";

exit;












sub queue2file {
	my ($queue, $name) = @_;
	my @list;
	while( my $item = $queue->dequeue_nb() ){
		push @list, $item;
	}	
	Utils::save_lines($name, \@list);
}

sub worker {
	my $agent = WWW::Mechanize->new(autocheck=>0);
	$agent->agent('Mozilla/5.0 (Windows; U; Windows NT 5.2; ru; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13 ( .NET CLR 3.5.30729; .NET4.0E)');
	while ( my $url = $taskqueue->dequeue_nb() ){

		$url =~ s/^https/http/i;
		print $url, "\n";
		
		$agent->get($url);
		unless($agent->success()){
			$failqueue->enqueue($url);
			print "Failed $url\n";
			next;
		}
		my $base = $agent->base()->as_string;
		my @links = $agent->links();
		my $counter = 0;
		foreach my $link (@links){
			my $href = $link->URI()->abs();
			unless($href =~ /^$base/){
				$counter++;
			}
		}

		if($counter<=$maxouters){
			$matchqueue->enqueue($url);
		} else {
			$dontmatchqueue->enqueue($url);
		}
		
		threads->yield();
	}
	
}








