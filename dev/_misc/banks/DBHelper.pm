package DBHelper;

use strict;
use warnings;

use utf8;

use DBI;

our $dbh;

our %cache_town_type_id;
our %cache_street_type_id;

our $dbname = 'r2_geo';


sub get_dbh {
	my $dbhx = DBI->connect("dbi:mysql:$dbname",'root','admin') or die "Connection Error: $DBI::errstr\n";
	$dbhx->{'mysql_enable_utf8'} = 1;
	$dbhx->do("set names utf8");
	$dbhx->{AutoCommit} = 0;
	return $dbhx;
}


sub get_currency_id_by_name {
	my ($dbh, $name) = @_;
	
	my $sql = "select * from class_currency where name=N?";
	my $sth = $dbh->prepare($sql);
	if (!$sth->execute($name)){
		log_error($DBI::errstr);
		die "SQL Error: $DBI::errstr\n";
	}
	my $row = $sth->fetchrow_hashref() or die "No currency $name";
	$sth->finish();
	return $row->{id};
}


sub log_error {
	my $text = shift;
	my $time = localtime(time);
	open LOG, '>>error-log.txt';
	print LOG "$time\n$text\n\n";
	close LOG;
}


sub search_region {
	my ($dbh, $name) = @_;
	my $where = 'where name=N? and country_id=?';
	my $sql = "select * from region where name=N? and country_id=?";
	my $sth = $dbh->prepare($sql);
	# use Russia as a country
	if (!$sth->execute($name, 1)){
		log_error($DBI::errstr);
		die "SQL Error: $DBI::errstr\n";
	}
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}


sub test_base {
	my $dbh = shift;
	my $sql = "select * from region where id=3";
	my $sth = $dbh->prepare($sql) or die "SQL Error: $DBI::errstr\n";
	$sth->execute() or die "SQL Error: $DBI::errstr\n";
	my $row = $sth->fetchrow_hashref();
	return $row;
}


1;
