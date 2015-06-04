use strict;
use warnings;

use threads;
use threads::shared;

use IO::Handle;

use Thread::Queue;
use Thread::Semaphore;


use Encode qw(encode_utf8);
use WWW::Mechanize;

our @agents:shared = (
	'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
	'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
	'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
	'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
	'Mozilla/5.0 (compatible; Konqueror/3; Linux)'
);




# restore state
my $prod_count = 0;
my %prod_registry:shared;
open SRC, 'output.xml';
while( my $line = <SRC> ){
	if ( $line && $line =~ /<id>(.*?)<\/id>/ ) {
		$prod_registry{$1} = 1;
		$prod_count++;
	}
}
close SRC;

print "There already are $prod_count products\n";




# get the main page
my $mech = WWW::Mechanize->new(autocheck=>0);

$mech->get('http://www.trade31.com/index.asp');

my $content = encode_utf8($mech->content);

#open SRC, '>page.txt';
#print SRC $content;
#close SRC;

$content =~ s/\r|\n|\t/ /g;

# extract category links
my $c = 0;

my $qCategories = Thread::Queue->new;
my $qProducts = Thread::Queue->new;

my $sem_xml = Thread::Semaphore->new(1);
my $sem = Thread::Semaphore->new(0);

open my( $io_fh ), ">>", "output.xml";
$io_fh->autoflush(1);

while ( $content =~ /<img src="images\/1\.gif"[^<]+<a href="(.*?)">/g ) #"
{
	$qCategories->enqueue("http://www.trade31.com/$1");
	$c++
}

# process the categories using the cat_worker

#print $c;
#exit;

my @ct;
foreach (1..15){
	push @ct, threads->new( \&cat_worker );
}

# wait...
my $work = 1;
do {
	sleep 3;
	{
		lock $$sem;
		$work = $$sem > 0;
	}
} while ( $qCategories->pending() || $work );

# detach the threads
foreach (@ct){
	$_->detach();
}


print "There are ", $qProducts->pending(), " products\n";


my @pt;
foreach (1..10){
	push @pt, threads->new( \&prod_worker );
}

# wait...
$work = 1;
do {
	sleep 3;
	{
		lock $$sem;
		$work = $$sem > 0;
	}
} while ( $qProducts->pending() || $work );

# detach the threads
foreach (@pt){
	$_->detach();
}

close $io_fh;




sub save_xml {
	my $str = shift;
	$sem_xml->down();
	print $io_fh "$str\n";
	$sem_xml->up();
}



sub prod_worker {
	my $mech = WWW::Mechanize->new(autocheck=>0);
	
	while ( defined( my $data = $qProducts->dequeue() ) ) {
		$sem->up;
		
		my ($catname, $url) = split '=>', $data;
		
		$mech->agent( get_agent() );
		if ($mech->get($url)){
			
			my $content =  encode_utf8( $mech->content() );
			$content =~ s/\r|\n|\t/ /g;
			
			# get product info

			my $id = '';
			if ( $content =~ /Product ID:<\/td>\s*<td>(\d+)<\/td>/ ){
				$id = $1;
			}

			my $name = '';
			if ( $content =~ /Product NO: <\/td>\s*<td>\s*(.*?)\s*<\/td>/ ){
				$name = $1;
			}

			my $descr = '';
			if ( $content =~ /Intro:<\/td>\s*<td>\s*(.*?)\s*<\/td>/ ){
				$descr = $1;
			}

			my $third_category = '';
			if ( $content =~ /Product Sort:<\/td>\s*<td>\s*(.*?)\s*<\/td>/ ){
				$third_category = $1;
			}

			my $pic = '';
			if ( $content =~ /<td align="left" ><img src="([^"]+)"><\/td>/ )#"
			{
				$pic = $1;
			}

			# correct category
			my @categories = split ' >> ', $catname;
			if ( $categories[1] ne $third_category ){
				push @categories, $third_category;
			}
			$catname = join ' > ', @categories;
			
			
			# download picture
			my $picname = '';
			if($pic){
				my @picnames = split '/', $pic;
				$picname = pop @picnames;
					
				$mech->agent( get_agent() );
				if( $mech->get("http://www.trade31.com/$pic") ){
					open IMG, ">img/$picname";
					binmode IMG;
					print IMG $mech->content();
					close IMG;
					
				} else {
					$picname = '';
				}

			}
			
			# make XML
			my $xmlstr = "<category>$catname</category><url>$url<url><id>$id</id><name>$name</name><description>$descr</description><image>$picname</image>";
			
			print "$id\n";			
			
			save_xml( $xmlstr );
			
		} else {
			$qProducts->enqueue("$data");
			print "xxx - $url\n";
		}
		$sem->down;
		threads->yield;
	}
	
	
}


sub cat_worker {
	my $mech = WWW::Mechanize->new;
	
	while ( defined( my $url = $qCategories->dequeue() ) ) {
		$sem->up;
		$mech->agent( get_agent() );
		if ($mech->get($url)){
			
			my $content =  encode_utf8( $mech->content() );
			$content =~ s/\r|\n|\t/ /g;
			
			# extract the two first categories
			$content =~ /<td\swidth="703">Current\sPosition:\s<a[^>]+>(.*?)<\/a>\s&gt;&gt;\s<a[^>]+>(.*?)<\/a>/;
			my $catname = "$1 >> $2";

print $catname, "\n";

			# search products
			while ( $content =~ /<a href="(productdisp\.asp\?id=(\d+))" target=_blank><img src="images\/view\.gif"/g )#'
			{
				unless( exists $prod_registry{$2} ){
					$qProducts->enqueue("$catname=>http://www.trade31.com/$1");
				}
			}

			# try to get the next page
			if ($content =~ /<A HREF=([^>]+)>next<\/A>/){
				$qCategories->enqueue("http://www.trade31.com/$1");
			}
			
		} else {
			$qCategories->enqueue("$url");
			print "xxx - $url\n";
		}
		$sem->down;
		threads->yield;
	}
	
	
}

sub get_agent {
	lock @agents;
	my $agent = shift @agents;
	push @agents, $agent;
	return $agent;
}

