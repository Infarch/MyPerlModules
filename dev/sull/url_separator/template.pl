use strict;
use warnings;

use utf8;

use threads;
use threads::shared;

use Error ':try';
use Thread::Queue;
use Thread::Semaphore;
use Encode 'encode';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;

our $break_application:shared = 0;


local $SIG{INT} = sub{
	# interrupt handler. useful for finalization after that user has pressed Ctrl+C
	print "Break signalled, please wait for finish\n";
	$break_application = 1;
	exit;
};

our $queue = Thread::Queue->new;
our $dest_queue = Thread::Queue->new;
our $sem = Thread::Semaphore->new(0);

# start
load_queue();
start_threads(3);
wait_for_finish();
finalize();

print "Done\n";
exit;


# ------------------------------ FUNCTIONS ------------------------------

# the main function. performs processing of an dequeued task.
sub executor {
	my ($agent, $id) = @_;
	
	my $task = "http://bestmebelik-spb.ru/shop/UID_$id.html";
	
	print $task, "\n";
	
	my $resp = $agent->get($task);
	unless($resp->is_success()){
		return $id;
	}
	
	my $content=$resp->decoded_content();
	
	if($content=~/<TITLE>Страница не найдена<\/TITLE>/){
		print "No ID $id\n";
		return undef;
	}
	
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	if($content=~/<div class="tab-page" id="tabPage1">(.+?)<\/div>\s<div class="tab-page"/){
		$content = $1;
		$content =~ s/^\s*<h2 class="tab">.+?<\/h2>//;
		$content =~ s/<script.*<\/script>//;
		if($content =~ /\S/){
			$content=~s/"/""/g; #"
			$dest_queue->enqueue("$id;\"$content\"");
		} else{
			print "Empty description ($id)\n";
		}
	}else{
		print "No description block ($id)\n";
	}
	
	return undef;
}

# Z127170787723
# R341004419740

sub load_queue {
	
	my @sources = qw(data_full_1.csv data_full_2.csv);

	my %registry;
	
	foreach my $source (@sources){
		open SRC, $source;
		my @lines = <SRC>;
		close SRC;
		
		foreach my $line (@lines){
			$line=~/^(\d+)/;
			$registry{$1} = 1;
		}
		
	}

	foreach(1..14606){
		
		$queue->enqueue($_) unless exists $registry{$_};
		
	}
	
	print $queue->pending(), " items in the queue\n";
	
}

sub finalize {
	#
	# write your code here in case when any finalization operations are required
	#
}

sub worker {

	my $agent = LWP::UserAgent->new;
	$agent->agent('Mozilla/5.0 (Windows NT 6.1; WOW64; rv:8.0) Gecko/20100101 Firefox/8.0');
	#$agent->max_redirect(0);
	#$agent->max_size(256);
	
	while ( 1 ){
		my $task = $queue->dequeue();
		$sem->up();
		
		my $error = 0;
		my $error_message = '';
		try {
			
			my $back = executor($agent, $task);
			if($back){
				print "$back was returned ti the queue\n";
				$queue->enqueue($back);
			}
			
		} catch Error::Simple with {
			$error_message = "A kind of exception";
			$error = 1;
		} otherwise {
			# fatal for application in whole
			$break_application = 1;
			$error_message = $@;
			$error = 1;
		};

		if($error){
			print "\nAn error happened: $error_message\n\n";
			$queue->enqueue($task) unless $break_application;
		}
		
		$sem->down();
		last if $break_application;
		threads->yield();
	}
	
}

sub collector {
	while ( 1 ){
		my $task = $dest_queue->dequeue();
		$sem->up();
		open XX, '>>data-rest.csv';
		print XX encode("cp-1251", $task), "\n";
		close XX;
		$sem->down();
		last if $break_application;
		threads->yield();
	}
	
}

sub start_threads {
	my $count = shift;
	foreach (1..$count){
		threads->create('worker')->detach();
	}
	threads->create('collector')->detach();
}

sub wait_for_finish {
	while(1){
		sleep 2;
		last if ($break_application || (!$queue->pending() && !$dest_queue->pending() )) && $$sem==0;
	}
}


