use strict;
use warnings;



use Date::Calc qw(Date_to_Time Time_to_Date);
use File::Copy;
use DBI;

use DXCC;

my $DATAFILE = "c:/work/Projects/radio/f_59150c19cd38d899.dat";

my $DB_HOST = "localhost";
my $DB_NAME = "radio";
my $DB_USER = "root";
my $DB_PASSWORD = "admin";

# read command line arguments
my $SOURCE = shift @ARGV;
my $contest = shift @ARGV;
my $year = shift @ARGV;

# make_rates.pl c:/work/projects/radio/testlog WTF 2015
if(!$SOURCE || !$contest || !$year || $year!~/^\d{4}$/){
	die "Usage: make_rates.pl [logs_folder|log_file] [contest] [year]";
}

unless(-e $SOURCE){
	die "$SOURCE does not exist";
}

my @logfiles;
if(-d $SOURCE){
	# this is a folder with files
	opendir SRC, $SOURCE;
	@logfiles = map { "$SOURCE/$_" } grep { /\.log$/i } readdir SRC;
	closedir SRC;
} else {
	# this is a file
	push @logfiles, $SOURCE;
}

# init an instance of the Call decoder
my $dxcc = DXCC->newFromFile($DATAFILE);

# get a database handler
my $dbh = DBI->connect("dbi:mysql:$DB_NAME:host=$DB_HOST", $DB_USER, $DB_PASSWORD) or 
		die "Connection Error: $DBI::errstr";
$dbh->{AutoCommit} = 0;


# do work
make_rate($_) foreach @logfiles;

exit;

###########################################

sub make_rate {
	my $filename = shift;
	print "$filename\n";
	
	my $loginfo = parse_log($filename);
	return unless $loginfo;
	
	my $qso = $loginfo->{'QSO'};
	my $deltatime = 0;
	my @rates;
	adjust_data($qso, \@rates, \$deltatime);
	
	my ($rh, $rh_start) = rate_hours(\@rates, $deltatime);
	my ($rm, $rm_start) = rate_minutes(\@rates, $deltatime);
	my $call = $loginfo->{'CALLSIGN'};
	my $callinfo = $dxcc->searchCall($call) || {
		cn => 'Unknown',
		cp => '',
		cnt => '',
		waz => 0,
		itu => 0
	};
	
	# check existence of such call in database
	
	my $ops = $loginfo->{'OPERATORS'} || '';
	$ops = '' if uc($ops) eq $call;
	my $op = $loginfo->{'CATEGORY-OPERATOR'} || '';
	my $transm = $loginfo->{'CATEGORY-TRANSMITTER'} || '';
	my $assist = $loginfo->{'CATEGORY-ASSISTED'} || '';
	my $band = $loginfo->{'CATEGORY-BAND'} || '';
	my $pwr = $loginfo->{'CATEGORY-POWER'} || '';
	
	my $cname = $callinfo->{'cn'};
	my $cpfx = $callinfo->{'cp'};
	my $continent = $callinfo->{'cnt'};
	my $waz = $callinfo->{'waz'};
	my $itu = $callinfo->{'itu'};
	
	my ($row) = sql_query(
		"select * from `QSO_RATES` where `CONTEST`=? and `YEAR`=? and `CALL`=?",
		$contest,$year,$call
	);
	
	if(defined $row){
		print "EXISTS\n";
		sql_query(
			"update `QSO_RATES` set `OPERATORS`=?,`QHOUR`=?,`QHOUR_START`=?,`QRATE`=?,`QRATE_START`=?,`OPERATOR`=?,`TRANSMITTER`=?,`ASSISTED`=?,`BAND`=?,`POWER`=?,`COUNTRY_NAME`=?,`COUNTRY_PFX`=?,`CONTINENT`=?,`WAZ`=?,`ITU`=? where `CONTEST`=? and `YEAR`=? and `CALL`=?",
			$ops,$rh,$rh_start,$rm,$rm_start,$op,$transm,$assist,$band,$pwr,$cname,$cpfx,$continent,$waz,$itu,$contest,$year,$call
		);
	} else {
		print "DOES NOT EXIST\n";
		sql_query(
			"insert into `QSO_RATES` (`CONTEST`,`YEAR`,`CALL`,`OPERATORS`,`QHOUR`,`QHOUR_START`,`QRATE`,`QRATE_START`,`OPERATOR`,`TRANSMITTER`,`ASSISTED`,`BAND`,`POWER`,`COUNTRY_NAME`,`COUNTRY_PFX`,`CONTINENT`,`WAZ`,`ITU`) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
			$contest,$year,$call,$ops,$rh,$rh_start,$rm,$rm_start,$op,$transm,$assist,$band,$pwr,$cname,$cpfx,$continent,$waz,$itu
		);
	}
	$dbh->commit();
	
	# print report
#	print "Call: $loginfo->{'CALLSIGN'}\n";
#	print "SOAP: $loginfo->{'SOAPBOX'}\n";
#	print "Hour rate: $rh ($rh_start)\n";
#	print "Minutes rate: $rm ($rm_start)\n";
#	
#	if($callinfo){
#		
#		print "Country name: $callinfo->{cn}\n";
#		print "WAZ: $callinfo->{waz}\n";
#		print "ITU: $callinfo->{itu}\n";
#		print "Continent: $callinfo->{cnt}\n";
#		print "Country pfx: $callinfo->{cp}\n";
#		
#	} else {
#		print "The call was not found in registry\n";
#	}
#	print "\n";

}


sub sql_query {
	my ($sql, @values) = @_;
	my $sth = $dbh->prepare($sql);
	$sth->execute(@values) or 
		die "SQL Error: ".$dbh->err()."\nSQL: $sql";
	my $rows = [];
	if($sth->{NUM_OF_FIELDS}){
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;
	return wantarray ? @$rows : $rows;
}

sub adjust_data {
	my ($qso, $rates, $dt_ref) = @_;
	# array of data must starts from a round hour (xx:00);
	my ($yy,$mm,$dd, $hour,$min) = Time_to_Date($qso->[0]);
	my $realtime = Date_to_Time($yy, $mm, $dd, $hour, $min, 0) / 60;
	my $mustbetime = Date_to_Time($yy, $mm, $dd, $hour, 0, 0) / 60;
	# furthermore, the 'must be' value is the delta to be substracted from other time values.
	my $dt = $mustbetime;
	$$dt_ref = $mustbetime;
	while($realtime > $mustbetime++){
		push @$rates, 0;
	}
	
	# populate list
	my $oldtime = shift @$qso;
	$oldtime = $oldtime / 60 - $dt;
	$rates->[$oldtime] = 1;
	foreach my $tm (@$qso){
		$tm = $tm / 60 - $dt;
		# 1: $tm==$oldtime : the same minute
		# 2: $tm==$oldtime+1 : the next minute
		# 3: a lacuna
		if($tm == $oldtime){
			$rates->[$tm]++;
		} elsif($tm == $oldtime+1){
			$oldtime = $tm;
			$rates->[$tm] = 1;
		} else {
			while(++$oldtime < $tm){
				$rates->[$oldtime] = 0;
			}
			$rates->[$tm] = 1;
			$oldtime = $tm;
		}
	}
	
	
}

sub rate_minutes {
	my ($rates, $deltatime) = @_;
	
	my $s;
	
	my $max = 0;
	my $start = 0;
	while ($start < @$rates){
		my $length = @$rates - $start > 60 ? 60 : @$rates - $start;
		my $cnt = 0;
		for(my $i=0; $i<$length; $i++){
			$cnt += $rates->[$i+$start];
		}
		if($cnt>$max){
			$max = $cnt;
			$s = $start;
		}
		$start++;
	}
	
	$s += $deltatime;
	$s *= 60;
	my($year,$month,$day, $hour,$min,$sec) = Time_to_Date($s);
	my $st = "$year-$month-$day $hour:$min";
	
	return ($max, $st);
}

sub rate_hours {
	my ($rates, $deltatime) = @_;
	my $max = 0;
	my $total = @$rates;
	my $start = 0;
	my $s;
	while($total > 0){
		my $length = $total > 60 ? 60 : $total;
		my $to = $start + $length;
		my $cnt = 0;
		for(my $i=$start; $i<$to; $i++){
			$cnt += $rates->[$i];
		}
		if($cnt>$max){
			$max = $cnt;
			$s = $start;
		}		
		$start = $to;
		$total -= $length;
	}
	
	$s += $deltatime;
	$s *= 60;
	my($year,$month,$day, $hour,$min,$sec) = Time_to_Date($s);
	my $st = "$year-$month-$day $hour:$min";

	return ($max, $st);
}

sub log_to_date {
	my $line = shift;
	my @parts = split /\s+/, $line;
	my $date = $parts[2] or die "No date";
	my $tm = $parts[3] or die "No time";
	my ($yy, $mm, $dd) = split '-', $date;
	my $hour = substr $tm, 0, 2;
	my $min = substr $tm, 2, 2;
	return ($yy,$mm,$dd, $hour,$min);
}

sub parse_log {
	my $filename = shift;
	
	my $no_lower_than = Date_to_Time(1970, 1, 2, 0, 0, 0);
	my %info;
	my @qso;
	
	local $/ = '';
	open SRC, $filename or die "Cannot open file $filename";
	my $entirelog = <SRC>;
	close SRC;
	
	my @lines = split /\r\n|\r|\n/, $entirelog;
	
	foreach my $line (@lines){
		if( $line =~ /^(.+?):\s+(.+)/ ){
			my $key = uc $1;
			my $value = $2;
			if($key eq 'QSO'){
				eval {
					my ($yy,$mm,$dd, $hour,$min) = log_to_date($value);
					my $x = Date_to_Time($yy, $mm, $dd, $hour, $min, 0);
					push @qso, $x if $x >= $no_lower_than;
				};
			} else {
				if(exists $info{$key}){
					# such key already exists: append the next line
					$info{$key} .= " $value";
				} else {
					# a new key
					$info{$key} = $value;
				}
			}
		}
	}
	
	return undef unless $info{'CALLSIGN'};

	$info{'CALLSIGN'} = uc $info{'CALLSIGN'};
	@qso = sort {$a <=> $b} @qso;
	$info{'QSO'} = \@qso;
	
	return \%info;
}

