# Creaded by Infarch
# Perl / C# / Web scraping - welcome to infarch74@gmail.com

use strict;
use warnings;

use threads;
use threads::shared;

use Error ':try';
use DBI;
use LWP::UserAgent;
use Thread::Queue;
use Thread::Semaphore;
use URI;


# database parameters
our $database = 'robots_sull';
our $user = 'root';
our $pass = 'admin';
our $host = 'localhost';
our $table = 'site';

# other parameters
our $datafile = 'list.txt';

# auxiliary variables
our $break_application:shared = 0;
our $pause_required:shared = 0;
our $pause = 10;

our $queue = Thread::Queue->new;
our $sem = Thread::Semaphore->new(0);

# start
my $dbh = get_dbh();
load_data($dbh, $datafile) if base_empty($dbh);

workflow();

# create the output text

do_output();


print "Done\n";
exit;


# ------------------------------ FUNCTIONS ------------------------------

sub do_output {

	print "Generating output file\n";

	open (CSV, ">output-$datafile") or die "Cannot make the output file\n";
	my $sql = "select URL, Host from $table where Done=1 and Host is not null";
	my $dbh = get_dbh();
	my $sth = $dbh->prepare($sql);
	$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	while (defined(my $aref = $sth->fetchrow_arrayref())){
		print CSV "$aref->[0] Host: $aref->[1]\n";
	}
	die $sth->errstr if $sth->err;
	$sth->finish;
	close CSV;
}

sub workflow {
	# don't load the big amount of data at once
	while(!$break_application && load_queue(5000)){
		start_threads(4);
		wait_for_finish();
		if($pause_required){
			print "Pause signalled, sleep $pause seconds\n";
			sleep $pause;
			$pause_required = 0;
		}
	}
}


sub executor_http {
	my ($dbh, $task) = @_;
	
	my $site = $task->[1];
	my $url = "$site/robots.txt";
	
	print "$url\n";
	
	my $ua = LWP::UserAgent->new();
	my $resp = $ua->get($url);
	my $host1;
	my $robots = 0;
	my $host_str;
	if ($resp->is_success()){
		$robots = 1;
		my $content = $resp->decoded_content();
		$content =~ s/[\r\n]+/\n/g;
		
		my $host = $site;
		$host =~ s/^http:\/\/(www\.|)//;
		
		if($content =~ /^host:\s*(.+)$/im){
			$host_str = $1;
			$host_str =~ s/:$//;
			$host_str =~ s/\s//g;
			$host_str =~ s/^http:\/\///i;
			$host_str =~ s/^www\.//i;
			if ($host ne $host_str){
				$host1 = $host_str;
				print "'$host' ne '$host_str'\n";
			}
		}
		
	}
	
	try {
		my $sql = "update $table set Done=?, Robots=?, RobotHost=?, Host = ? where ID = ?";
		do_query($dbh, sql=>$sql, values=>[1, $robots, $host_str, $host1, $task->[0]]);
	} otherwise {
		my $sql = "update $table set Done=2 where ID = $task->[0]";
		do_query($dbh, sql=>$sql);
	};
	
}

sub load_queue {
	my $limit = shift;
	
	print "Populating the work queue\n";
	
	my $dbh = get_dbh();
	my $sql = "select ID, URL from $table where Done=0 limit $limit";
	my $rows = do_query($dbh, sql=>$sql, arr_ref=>1);
	my $counter = 0;
	
	foreach my $row (@$rows){
		my @task:shared = (
			"$row->[0]", "$row->[1]"
		);
		$queue->enqueue(\@task);
		$counter++;
	}
	
	return $counter;
}


sub worker {
	my $dbh = get_dbh();
	while ( 1 ){
		my $task = $queue->dequeue();
		$sem->up();
		
		my $error = 0;
		my $error_message = '';
		try {
			
			executor_http($dbh, $task);
			
		} catch Error::Simple with {
			#my $e = shift;
			$error_message = $@->text() . ' (line ' . $@->line() . ')';
			$error = 1;
			$break_application = 1;
		} otherwise {
			$break_application = 1;
			$error_message = $@;
			$error = 1;
		};

		if($error){
			print "\nAn error happened: $error_message\n\n";
			$queue->enqueue($task) unless $break_application;
		}
		
		$sem->down();
		last if ($break_application || $pause_required);
		threads->yield();
	}
	
}

sub start_threads {
	my $count = shift;
	foreach (1..$count){
		my $th = threads->create('worker');
		$th->detach() if defined $th;
	}
}

sub wait_for_finish {
	while(1){
		sleep 2;
		last if ($pause_required || $break_application || !$queue->pending()) && $$sem==0;
	}
}

sub get_dbh {
	my $dbh = DBI->connect("dbi:mysql:$database:host=$host", $user, $pass) or 
		die "Connection Error: $DBI::errstr\n";
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	$dbh->{AutoCommit} = 1;
	return $dbh;
}

sub base_empty {
	my $dbh = shift;
	
	my $sql = "Select count(*) from $table";
	my $count = do_query($dbh, sql=>$sql, single=>1);
	
	if($count){
		print "Database is not empty\n";
		return 0;
	} else {
		print "Database is empty\n";
		return 1;
	}
	
}

sub load_data {
	my ($dbh, $datafile) = @_;
	
	print "Loading $datafile into database. It might take a long time.\nSeriously!\n";
	
	open (SRC, $datafile) or die "Cannot open file $datafile: $!";
	# just skip the first line
	my $line;
	# load the whole file, convert to database records
	my $counter = 0;
	my $sql = "insert into $table (URL) values (?)";
	my $sth = $dbh->prepare($sql);
	foreach $line (<SRC>){
		chomp $line;
		my $uri = URI->new($line);
		$line = 'http://' . $uri->host();

		if( (++$counter % 20000) == 0 ){
			print "$counter\n";
		}
		#if ($line !~ /\.narod\.ru$/i){
			$sth->execute($line) or 
				throw Error::Simple("SQL Error: ".$dbh->err()." ($sql)\n($line)\n");
		#}
	}
	
	$sth->finish;
	
	close SRC;
}

sub do_query {
	my $dbh = shift;
	my %params = @_;

	my $sql = $params{sql};
	my $hashref = exists $params{hashref} ? $params{hashref} : 0;
	my $arr_ref = exists $params{arr_ref} ? $params{arr_ref} : 0;
	my $single  = exists $params{single}  ? $params{single}  : 0;

	my @vals;
	if (exists $params{values}){
		my $rf = ref $params{values};
		if($rf && $rf eq 'ARRAY'){
			@vals = @{$params{values}};
		} else {
			throw Error::Simple("The 'values' parameter should be an array reference");
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or 
			throw Error::Simple("SQL Error: ".$dbh->err()." ($sql)\n(@vals)\n");
	} else {
		$sth->execute() or 
			throw Error::Simple("SQL Error: ".$dbh->err()." ($sql)\n");
	}

	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} elsif($hashref) {
		$rows = $sth->fetchall_arrayref({});
	} elsif($arr_ref || $single) {
		$rows = $sth->fetchall_arrayref([]);
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	if($single){
		return $rows->[0]->[0];
	}
	return wantarray ? @{$rows} : $rows;
}
