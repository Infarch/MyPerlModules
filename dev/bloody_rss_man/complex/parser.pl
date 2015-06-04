use strict;
use warnings;

use utf8;
use open qw(:std :utf8);

use threads;
use threads::shared;

use Utils;


use SimpleConfig;

use HTML::Entities;
use Thread::Semaphore;
use Thread::Queue;
use LWP::UserAgent;



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


our $wcount:shared = $constants{Parser}{Words};
our $title:shared = $constants{Parser}{IncludeTitles};
my $threads = $constants{Parser}{Threads};
our $pause:shared = $constants{Parser}{Pause};

my @dflist = load_lines($constants{General}{DomainFolderFile});
if (@dflist==0){
	set_state('upload.ready');
	exit;
}


# clean up string collection file
save_lines($constants{General}{StringCollectionFile}, []);

# read the 'cutlist'
my $cutlist = 'cutlist.txt';
our @cutlist:shared;
if (-e $cutlist && -f $cutlist){
	print "Reading cutlist...\n";
	@cutlist = load_lines('cutlist.txt', not_empty=>1);
}

# read queries from a file
print "Reading queries...\n";

my @qlist = load_lines('queries.txt', not_empty=>1);


# there should be exactly xx queries according to config file
my $qcount = $constants{Parser}{Queries};
my @work_part;
my @next_part;
if($qcount > @qlist){
	set_state('upload.ready');
	print "Warning! There are no enough queries!\n";
	exit;
}

@work_part = @qlist[0..$qcount-1];

if ($qcount < @qlist){
	@next_part = @qlist[$qcount..$#qlist];
}

# save files
save_lines('queries.txt', \@next_part);
save_lines($constants{General}{KeyWordsFile}, \@work_part);

foreach my $query (@work_part){
	$query =~ s/\s+/+/g;
	$queue->enqueue("$query");
}

print "Starting work...\n";

# starting workers
foreach (1..$threads) {
	threads->create( \&worker )->detach();
}

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


my $timeend = time;

print 'Done. Execution took about ', $timeend-$timestart, " seconds\n\n";









# ----------- functons ---------------

#my $ua = new LWP::UserAgent;
#$ua->agent("Mozilla/6.0");
#$ua->proxy('http',$proxy);
#my $req = new HTTP::Request GET => $url;
#$req->proxy_authorization_basic($username, $password);
#my $res = $ua->request($req);

sub worker {
	
	my $ua = LWP::UserAgent->new();
	$ua->timeout(20);
	
	my $proxy = $constants{Parser}{Proxy};
	if($proxy){
		$ua->proxy('http', "http://$proxy");
	}
	
	while ( defined ( my $query = $queue->dequeue() ) ) {
		$work_sem->up();
		
		$ua->agent( get_agent() );
		my $resp = $ua->get("http://blogsearch.google.com/blogsearch_feeds?hl=en&q=$query&ie=utf-8&num=100&output=rss");
		
		if( $resp->is_success() ){
			
			my $content = get_pretty_content( $resp );
			my @items = ( $content =~ /<item>.*?<description>(.*?)<\/description>/g );
			
			my $temp_data = $query;
			$temp_data =~ s/\+/ /g;

			if (@items > 0){
				
				my $output_data = '';
				
				foreach (@items){
					
					# remove html tags
					my $str = decode_entities($_);
					$str =~ s/<[^>]*>//g;
					
					# apply the cut list
					for(my$ i=0; $i<@cutlist; $i++){
						my $cstr = $cutlist[$i];
						my $idx = index ($str, $cstr);
						if($idx==0){
							$str = substr ($str, length $cstr, ((length $str) - (length $cstr)));
							$str =~ s/^\s+//;
						}
					}
					
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
						while( $tmp =~ /([!?")])/g ) #"
						{
							$xx = $1;
						}
						$str = (substr $str, 0, (length $str) - ( length $tmp)) . $xx;
					}
					$str .= '.' if ($str !~ /[?!]$/);
	
					
					$output_data .= "$str\n";
					
				}
				
				if ($title) {
					my @titles = ( $content =~ /<item>.*?<title>(.*?)<\/title>/g );
					foreach (@titles){
						# remove html tags
						my $ttl = decode_entities( decode_entities($_) );
						$ttl =~ s/<[^>]*>//g;
						
						$ttl =~ s/( |)\.\.\.$//;
						
						$ttl .= '.' if ( $ttl !~ /[.!?]$/ );
						
						$output_data .= "$ttl\n";
					}
				}
				$output_data .= "\n";
				do_output( $output_data );

			}
			
			print "$temp_data : ", scalar @items, "\n";
			
		} else {
			# return the failed query to the queue
			$queue->enqueue("$query");
			print "Request failed: ", $resp->status_line(), "\n";
		}
		
		$work_sem->down();
		threads->yield();
		sleep $pause;
	}
	
}

sub get_pretty_content {
	my $response = shift;
	
	my $content = $response->decoded_content();
	
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
	open DST, '>>', $constants{General}{StringCollectionFile};
	print DST $data;
	close DST;
	$file_sem->up();
}

