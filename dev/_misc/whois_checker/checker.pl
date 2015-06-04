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


# database parameters
our $database = 'alexa';
our $user = 'root';
our $pass = 'admin';
our $host = 'localhost';
our $table = 'domain';

# other parameters
our $datafile = 'domains.csv';


# auxiliary variables
our $stage = 0;
our $break_application:shared = 0;
our $pause_required:shared = 0;
our $pause = 10;

our $queue = Thread::Queue->new;
our $sem = Thread::Semaphore->new(0);

# start
my $dbh = get_dbh();
load_csv($dbh, $datafile) if base_empty($dbh);

workflow(0);

# fething data from network if finished. now we should parse that data

workflow(1);

# create the output CSV

do_output();


print "Done\n";
exit;


# ------------------------------ FUNCTIONS ------------------------------

sub do_output {

	print "Generating output file\n";

	open (CSV, ">output-$datafile") or die "Cannot make the output file\n";
	print CSV '"domain";"delegated";"created";"ip";"yandex pages";"loaded date";"CY";"zerkalo";"email";"owner"', "\n";
	my $sql = "select Name, Delegated, CreatedDate, IP, YandexPages, LoadedDate, CY, Mirror, Email, Owner from $table where Done=1";
	my $dbh = get_dbh();
	my $sth = $dbh->prepare($sql);
	$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	while (defined(my $aref = $sth->fetchrow_arrayref())){
		my @list;
		foreach (@$aref){
			my $item = defined $_ ? $_ : '';
			push @list, '"'.$item.'"';
		}
		print CSV join(';', @list), "\n";
	}
	die $sth->errstr if $sth->err;
	$sth->finish;
	close CSV;
}

sub workflow {
	my $current_stage = shift;
	$stage = $current_stage;
	# don't load the big amount of data at once
	while(!$break_application && load_queue(5000)){
		start_threads(10);
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
	
	my $url = "http://whois7.ru/?q=$task->[1]";
	
	print "Checking $task->[1]\n";
	
	my $ua = LWP::UserAgent->new();
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6');
	my $resp = $ua->get($url);
	while (!$resp->is_success()){
		print "$task->[1] failed, try again\n";
		sleep 1;
		$resp = $ua->get($url);
	}
	
	my $raw;
	
	my $content = $resp->content();

	if ($content =~ /<code>(.*?)<\/code>/s){
		$content = $1;
	} else {
		# looks strange, just skip for now
		print "Skipping a strange error\n";
		return;
	}

	if($content =~ /No entries found for the selected source/s){
		# no data
		$raw = 'none';
	} elsif (
		$content =~ /
			You\shave\sexceeded\sallowed\sconnection\srate |
			You\sare\snot\sallowed\sto\sconnect |
			Sorry\sfor\stemporary\sdifficulties\.\sTry\sto\srequest\sservice\slater
		/sxi	
	){
		# limitation
		$pause_required = 1;
		return;
	} elsif ($content!~/registrar/s){
		# looks strange, just skip for now
		print "Skipping a strange error\n";
		return;
	}
	
	$raw = $content unless $raw;
		
	my $sql = "update $table set Raw = ? where ID = ?";
	do_query($dbh, sql=>$sql, values=>[$raw, $task->[0]]);
	
}

sub executor_text {
	my ($dbh, $task) = @_;

	print "Parsing ID $task->[0]\n";

	my $raw = $task->[1];
	
	my ($owner, $email, $registerdate);
	
	if ($raw ne 'none'){
		
		if( $raw =~ /person:\s+(.*?)$/m){
			$owner = $1;
			$owner =~ s/<[^>]+>//g;
		}
		
#		if( $raw =~ /created:\s+(.*?)$/m){
#			$registerdate = $1;
#		}
		
		if( $raw =~ /e-mail:\s+(.*?)\.*$/m){
			$email = $1;
			$email =~ s/<[^>]+>//g;
		}
		
	}
	
	#my $sql = "update $table set Owner = ?, Email = ?, RegisterDate = ?, Done = 1 where ID = ?";
	#do_query($dbh, sql=>$sql, values=>[$owner, $email, $registerdate, $task->[0]]);
	
	my $sql = "update $table set Owner = ?, Email = ?, Done = 1 where ID = ?";
	do_query($dbh, sql=>$sql, values=>[$owner, $email, $task->[0]]);

}

sub load_queue {
	my $limit = shift;
	
	print "Populating the work queue\n";
	
	my $dbh = get_dbh();
	my ($datafield, $clause);
	if($stage==0){
		$datafield = 'Name';
		$clause = 'Raw is null';
	} else {
		$datafield = 'Raw';
		$clause = 'Done=0';
	}
	my $sql = "select ID, $datafield from $table where $clause limit $limit";
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
			
			if($stage==0){
				executor_http($dbh, $task);
			} else {
				executor_text($dbh, $task);
			}
			
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

sub load_csv {
	my ($dbh, $datafile) = @_;
	
	print "Loading $datafile into database. It might take a long time.\nSeriously!\n";
	
	open (SRC, $datafile) or die "Cannot open file $datafile: $!";
	# just skip the first line
	my $line = <SRC>;
	# load the whole file, convert to database records
	my $counter = 0;
	my $sql = "insert into $table (Name, Delegated, CreatedDate, IP, YandexPages, LoadedDate, CY, Mirror) values (?,?,?,?,?,?,?,?)";
	my $sth = $dbh->prepare($sql);
	foreach $line (<SRC>){
		if( (++$counter % 20000) == 0 ){
			print "$counter\n";
		}
		
		# split the line
		my @parts = split ';', $line;
		foreach (@parts){
			# remove quotes
			s/^"//;
			s/"$//;
		}
		# insert into database
		
		$sth->execute(@parts) or 
			throw Error::Simple("SQL Error: ".$dbh->err()." ($sql)\n(@parts)\n");
		
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
