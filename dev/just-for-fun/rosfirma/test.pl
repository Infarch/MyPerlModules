use strict;
use warnings;
use threads;



threads->create('ww', 1);
threads->create('ww', 1);
threads->create('ww', 1);

threads->create('ww', 0);
threads->create('ww', 0);
threads->create('ww', 0);


sleep 1;

print 'Total: ', scalar threads->list(), "\n";
print 'Running: ', scalar threads->list(threads::running), "\n";
print 'Joinable: ', scalar threads->list(threads::joinable), "\n";










sub ww {
	my ($stop) = @_;
	
	my $a = 0;
	while (!$stop){
		$a += 2;
	}
	
	return $a;
}