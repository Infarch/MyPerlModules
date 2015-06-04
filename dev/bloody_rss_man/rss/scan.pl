use strict;
use warnings;

use threads;
use threads::shared;

use Encode qw(encode_utf8 encode);
use HTML::Entities;
use Thread::Semaphore;
use Thread::Queue;
use WWW::Mechanize;

our @x_agents:shared = (
	'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
	'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
	'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
	'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
	'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)'
);

our @agents:shared = (
	'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)',
);

our $file_sem = Thread::Semaphore->new(1);
our $work_sem = Thread::Semaphore->new(0);
our $queue = Thread::Queue->new;

my $timestart = time;



# get arguments
our $wcount:shared = 999;
our $title:shared = 0;
my $threads = 10;
our $pause:shared = 1;

foreach my $arg ( @ARGV ){
	
	if ( $arg =~ /^words(\d+)$/ ){
		$wcount = $1;
	}

	if ( $arg =~ /^title$/ ){
		$title = 1;
	}

	if ( $arg =~ /^threads(\d+)$/ ){
		$threads = $1;
	}

	if ( $arg =~ /^pause(\d+)$/ ){
		$pause = $1;
	}
	
}


# read queries from a file
print "Reading queries...\n";
open SRC, 'queries.txt';
while (<SRC>){
	chomp;
	s/\s+/+/g;
	$queue->enqueue("$_") if $_;
}
close SRC;

print "Starting work...\n";

# starting 20 workers
my @workers = map { threads->new( \&worker ) } (1..$threads);

print "Please wait for finishing\n";

# wait...
my $work = 1;
do {
	sleep 3;
	{
		lock $$work_sem;
		$work = $$work_sem > 0;
	}
} while ( $queue->pending() || $work );

sleep 3;

# detach the threads
foreach (@workers){
	$_->detach();
}

my $timeend = time;

print 'Done. Execution took about ', $timeend-$timestart, ' seconds';









# ----------- functons ---------------

sub worker {
	
	my $mech = WWW::Mechanize->new(autocheck=>0);
	
	while ( defined ( my $query = $queue->dequeue() ) ) {
		$work_sem->up();
		
		$mech->agent( get_agent() );
		my $ok = $mech->get("http://blogsearch.google.com/blogsearch_feeds?hl=en&q=$query&ie=utf-8&num=100&output=rss");

		if( $ok ){
			
			my $content = get_pretty_content( $mech );
			my @items = ( $content =~ /<item>.*?<description>(.*?)<\/description>/g );
			
			my $temp_data = $query;
			$temp_data =~ s/\+/ /g;

			if (@items > 0){
				
				my $output_data = "<mainone>$temp_data<maintwo>\n";
				
				foreach (@items){
					
					# remove html tags
					my $str = decode_entities($_);
					$str =~ s/<[^>]*>//g;
					
					# make corrections
	
					my $pos1 = 0;
					while ( $str =~ /[?!]/g ){
						$pos1 = (pos $str) - 2;
					}
					
					my $limit = $wcount;
				
					while ($limit-- > 0){
						
						my $short_pos;
						while ( $str =~ /\b(\w{1,3})\b/g ){
							$short_pos = (pos $str) - 1 - length $1;
						}
					
						my $large_pos;
						while ( $str =~ /\b(\w{4,})\b/g ){
							$large_pos = (pos $str) - 1 - length $1;
						}
					
					
						if ( (defined $short_pos) && (defined $large_pos) && ($short_pos > $large_pos) && ($short_pos > $pos1) ){
							$str = substr $str, 0, $short_pos+1;
						} else {
							$limit = 0;
						}
				
					}
				
					# do trim
					
					if ( $str =~ /\w(\W*)$/ ){
						my $tmp = $1;
						my $xx = '';
						while( $tmp =~ /([!?")])/g ){ #"
							$xx = $1;
						}
						$str = (substr $str, 0, (length $str) - ( length $tmp)) . $xx;
					}
					$str .= '.' if ($str !~ /[?!]$/);
	
					
					$output_data .= "$str\n\n";
					
				}
				
				if ($title) {
					my @titles = ( $content =~ /<item>.*?<title>(.*?)<\/title>/g );
					foreach (@titles){
						# remove html tags
						my $ttl = decode_entities( decode_entities($_) );
						$ttl =~ s/<[^>]*>//g;
						
						$ttl =~ s/( |)\.\.\.$//;
						
						$ttl .= '.' if ( $ttl !~ /[.!?]$/ );
						
						$output_data .= "$ttl\n\n";
					}
				}
				
				do_output( $output_data );

			}
			
			print "$temp_data : ", scalar @items, "\n";
			
		} else {
			# return the failed query to the queue
			$queue->enqueue("$query");
		}
		
		$work_sem->down();
		threads->yield();
		sleep $pause;
	}
	
}

sub get_pretty_content {
	my $mech = shift;
	
	my $content = encode_utf8( $mech->content() );
	
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	return $content;
}

sub get_agent {
	lock @agents;
	my $agent = shift @agents;
	push @agents, $agent;
	return $agent;
}

sub do_output {
	my $data = shift;
	$file_sem->down();
	open DST, '>>result.txt';
	print DST $data, "\n";
	close DST;
	$file_sem->up();
}






