use strict;
use warnings;

use threads;
use threads::shared;

use LWP::Simple 'getstore';


my @list:shared;
my $rlock:shared;

# load list
open SRC, 'list.txt';
while (my $line = <SRC>){
	chomp $line;
	push @list, $line;
}
close SRC;


# prepare directories
if(!-e 'lib' && !-d 'lib'){
	mkdir 'lib' or die $!;
}

my %reg;
foreach my $line (@list){
	my ($cat, $name, $size) = split ' ', $line;
	next if exists $reg{$cat};
	if(!-e "lib/$cat" && !-d "lib/$cat"){
		mkdir "lib/$cat" or die $!;
	}
	$reg{$cat} = 1;
}

# start workers
foreach (1..10){
	threads->create('worker');
}

# wait for finish
my $work;
do {
	sleep 60;
	my @running = threads->list(threads::running);
	$work = @running > 0;
	my @joinable = threads->list(threads::joinable);
	foreach (@joinable){
		$_->join();
	}
} while ($work);


print "\nDone!\n";




exit;

sub worker {
	my $item;
	do{
		{
			lock (@list);
			$item = shift @list;
		}
		if($item){
			process_file($item);
		}
		threads::yield();
	} while ($item);
}

sub process_file {
	my $line = shift;
	my ($cat, $name, $size) = split ' ', $line;
	my $path = "lib/$cat/$name";
	my $url = "http://book-download.pp.ua/lib/$cat/$name";
	if (-e $path){
		print "$name skipped\n";
		return;
	} 
	my $code = getstore($url, $path);
	if ($code == 200){
		print "$name stored\n";
	} else {
		report_error($code, $path);
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
