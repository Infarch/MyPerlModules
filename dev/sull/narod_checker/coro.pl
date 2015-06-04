use strict;
use warnings;

use Coro;
use Coro::LWP;
use LWP::Simple;
use URI;

print "Hello\n";


my $sig = new Coro::Semaphore 200;

my @coros;

my $t1 = time;

open SRC, 'list.txt';
while(<SRC>){
	chomp;
	push @coros, make_coro($_);
}
close SRC;
#foreach(1..3000){
#	push @coros, make_coro("http://www.face.by");
#}

open MM, '>matches.txt';
for(@coros){
	my $x = $_->join;
	if($x){
		print MM $x, "\n";
	}
}
close MM;

my $t2 = time;

print "Took " . ($t2-$t1) . "\n";

exit;

sub make_coro {
	my ($coro_url) = @_;
	
	return async {
		
		my $url = lc shift;
		
		my $host = URI->new($url)->host();
		
		my $result;
		
		my $s = 0;
		my $robots = try_get($host);
		
		if( $robots ){
			$s++;
			$host =~ s/^www\.//i;
			
			if($robots =~ /^host:\s*(.+)$/im){
				my $host_str = lc $1;
				$host_str =~ s/:$//;
				$host_str =~ s/\s//g;
				$host_str =~ s/^http:\/\///;
				$host_str =~ s/^www\.//;
				if($host ne $host_str){
					$result = "$url Host $host_str\n";
					$s++;
				}
			}

		}
		
		print "$s : $url\n";
		
		return $result;
		
	} $coro_url;
	
	
}

sub try_get {
	my $hh = shift;
	$sig->down();
	my $content = get("http://$hh/robots.txt");
	$sig->up();
	return $content;
}