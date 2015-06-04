use strict;
use warnings;

use threads;
use threads::shared;

use Error ':try';
use Thread::Queue;
use Thread::Semaphore;




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
finalize();

print "Done\n";
exit;


# ------------------------------ FUNCTIONS ------------------------------

# the main function. performs processing of an dequeued task.
sub executor {
	my $task = shift;
	
	#print "-=$task=-\n";
	
}

sub load_queue {
	#
	# write your code here
	# while(...){ $queue->enqueue($...) }
	#
}

sub finalize {
	#
	# write your code here in case when any finalization operations are required
	#
}

sub worker {
	while ( 1 ){
		my $task = $queue->dequeue();
		$sem->up();
		
		my $error = 0;
		my $error_message = '';
		try {
			
			executor($task);
			
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

sub start_threads {
	my $count = shift;
	foreach (1..$count){
		threads->create('worker')->detach();
	}
}

sub wait_for_finish {
	while(1){
		sleep 2;
		last if ($break_application || !$queue->pending()) && $$sem==0;
	}
}


