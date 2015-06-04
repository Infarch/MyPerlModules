use strict;
use warnings;

use threads;
use threads::shared;

use LWP::Simple 'getstore';
use Thread::Queue;
use Thread::Semaphore;


my $rlock:shared;

our $break_application:shared = 0;


local $SIG{INT} = sub{
	# interrupt handler. useful for finalization after that user has pressed Ctrl+C
	print "Break signalled, please wait for finish\n";
	$break_application = 1;
	exit;
};

our $queue = Thread::Queue->new;
our $sem = Thread::Semaphore->new(0);

# start
load_queue();
start_threads(10);
wait_for_finish();

print "Done\n";
exit;


# ------------------------------ FUNCTIONS ------------------------------

# the main function. performs processing of an dequeued task.
sub executor {
	my $path = shift;
	
	my $url = "http://book-download.pp.ua/$path";
	if (-e $path){
		print "$path skipped\n";
		return;
	}
	my $code = getstore($url, $path);;
	if ($code == 200){
		print "$path stored\n";
	} else {
		print "$path failed\n";
		report_error($code, $path);
	}
	
}

sub load_queue {

	# prepare root directory
	if(!-e 'lib' && !-d 'lib'){
		mkdir 'lib' or die $!;
	}

	my %reg;

	# load list
	open SRC, 'list.txt';
	while (my $line = <SRC>){
		chomp $line;
		my ($cat, $name, $size) = split ' ', $line;
		$queue->enqueue("lib/$cat/$name");
		next if exists $reg{$cat};
		if(!-e "lib/$cat" && !-d "lib/$cat"){
			mkdir "lib/$cat" or die $!;
		}
		$reg{$cat} = 1;
	}
	close SRC;
}

sub worker {
	while ( 1 ){
		my $task = $queue->dequeue();
		$sem->up();
		
		my $error = 0;
		my $error_message = '';
			
			executor($task);
			
		if($error){
			print "\nAn error happened: $error_message\n\n";
			$queue->enqueue($task) unless $break_application;
		}
		
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
}

sub wait_for_finish {
	while(1){
		sleep 10;
		last if ($break_application || !$queue->pending()) && $$sem==0;
	}
}

sub report_error {
	my ($code, $name) = @_;
	{
		lock ($rlock);
		open RR, '>>report.txt';
		print RR "$code $name\n";
		close RR;
	}
}

