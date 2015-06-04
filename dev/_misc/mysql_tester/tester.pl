use strict;
use warnings;

use DBI;
use Time::HiRes qw( gettimeofday tv_interval );


# configuration
our $db_host = 'localhost';
our $db_user = 'root';
our $db_password = 'admin';

our $database = 'test';
our $table = 'test_table';

our $tests = 500;


# for web interface
print "Content-type: text/html\r\n\r\n";


# start testing

my $dbh = get_dbh();

check_table($dbh);

my $total = 0;

print "Use loop value $tests\n";

$total += test_insert($dbh);
$total += test_select($dbh);
$total += test_delete($dbh);

print "Total: $total seconds\n";

$dbh->disconnect();

# finish
exit;




# test functions

sub test_delete {
	my $dbh = shift;
	
	my $sql = "delete from $table limit 1";
	
	return do_test($dbh, $sql, 'DELETE');
}

sub test_select {
	my $dbh = shift;
	
	my $sql = "select count(*) from $table where IntField>555 and TextField like '%amet%' and TextField like '%eleifend%'";
	
	return do_test($dbh, $sql, 'SELECT');
}

sub test_insert {
	my $dbh = shift;
	
	my $i = '123456';
	my $t = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris semper tempus laoreet. Nulla dictum fermentum nibh, quis vestibulum ipsum vehicula vel. Mauris magna massa, dictum quis lobortis in, tempus et ipsum. Etiam eget justo non mauris pharetra adipiscing. Phasellus ornare, lorem at posuere fermentum, orci elit blandit augue, vel volutpat velit velit auctor sem. Duis volutpat suscipit justo quis vestibulum. Donec dolor purus, ultrices in porttitor et, pharetra id mi. Nulla molestie ornare sodales. Nam fermentum tortor quis mauris ultricies ut faucibus lorem facilisis. Nunc sollicitudin, dui ut iaculis porta, odio mi vehicula dui, eget sodales justo augue vel metus. Integer vel risus ut mauris mollis placerat. Quisque vel mauris lorem. Morbi sit amet hendrerit quam. Cras nec libero urna. In magna nunc, eleifend nec tristique sit amet, eleifend sit amet purus. Integer urna nunc, sodales quis gravida quis, tristique at enim. Suspendisse potenti.';
	
	my $sql = "insert into $table (IntField, textField) values ($i, '$t')";
	
	return do_test($dbh, $sql, 'INSERT');
}

# auxiliary functions

sub do_test {
	my ($dbh, $sql, $name) = @_;
	my $t0 = [gettimeofday];
	foreach (1..$tests){
		do_query($dbh, $sql);
	}
	my $t1 = [gettimeofday];
  my $interval = tv_interval $t0, $t1;
	print "$name took $interval seconds\n";
	return $interval;
}

sub check_table {
	my $dbh = shift;
	my $sql = "DROP TABLE IF EXISTS $table";
	do_query($dbh, $sql);
	$sql = qq(
		CREATE TABLE $table (
		  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
		  `IntField` int(10) unsigned NOT NULL,
		  `TextField` text NOT NULL,
		  PRIMARY KEY (`ID`)
		);
	);
	do_query($dbh, $sql);
}

sub do_query {
	my ($dbh, $sql) = @_;

	my $sth = $dbh->prepare($sql);
	$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	
	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	return $rows;
}

sub get_dbh {
	my $dbh = DBI->connect("dbi:mysql:$database:host=$db_host", $db_user, $db_password) or 
		die "Connection Error: $DBI::errstr\n";
	return $dbh;
}
