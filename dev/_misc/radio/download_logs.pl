use strict;
use warnings;

use LWP::Simple;
use URI;
use File::Path;

# download_logs.pl http://cqww.com/publiclogs/2011cw/ c:/work/Projects/radio/logs
#my $URL = "http://cqww.com/publiclogs/2011cw/";
#my $STORAGE = "c:/work/Projects/radio/logs";
my $MAX_ERRORS = 5;

my $URL = shift @ARGV;
my $STORAGE = shift @ARGV;

if(!$URL || !$STORAGE){
	die "Usage: download_logs.pl[url] [logs_folder]";
}

unless(-e $STORAGE && -d $STORAGE){
	#die "$STORAGE does not exist";
	mkpath $STORAGE;
}

print "Start reading files list\n";

my $page = get($URL) or die "Cannot open $URL";

# return URI->new($url)->abs($self->get('URL'))->as_string;

# extract files links
my @files;

while($page=~/<a href="([^.]+.log)">[^<]+<\/a>/g){
	push @files, $1;
}

print "There is ", scalar @files, " files for downloading\n";

my $errors = $MAX_ERRORS;
foreach my $file (@files){
	
	my $filepath = "$STORAGE/$file";
	print $file, "\n";
	
	# skip if exists
	next if -e $filepath && -f $filepath && -s $filepath>0;
	
	# download
	my $status = getstore(URI->new($file)->abs($URL), $filepath);
	# wait a second
	sleep 1;
	# check the status code, try again if failed
	if($status != RC_OK){
		die "Connection error" unless $errors--;
		redo;
	} else {
		# all right, reset the error counter
		$errors = $MAX_ERRORS;
	}
}
