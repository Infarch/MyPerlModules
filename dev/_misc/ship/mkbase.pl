use strict;
use warnings;


use DBI;

my $dbfile = 'database.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","",{ RaiseError => 1 }) or die $DBI::errstr;


my $sql = qq(

CREATE TABLE shipdata (
    shipdata_id INTEGER NOT NULL,
    ship_id INTEGER,
    colval_rus TEXT NOT NULL,
    colval_eng TEXT NOT NULL,
    codename TEXT,
    CONSTRAINT PK_shipdata PRIMARY KEY (shipdata_id)
);

CREATE    FOREIGN KEY (ship_shipdata) REFERENCES ship (ship_id);
CREATE    FOREIGN KEY (shipvoc_shipdata) REFERENCES shipvoc (codename);


);


do_query($dbh, sql=>$sql);









sub do_query {
	my ($dbh, %params) = @_;
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
			die "The 'values' parameter should be an array reference";
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or die "SQL Error: ".$dbh->err()." ($sql)";
	} else {
		$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
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
		return @$rows>0 ? $rows->[0]->[0] : undef;
	}
	return $rows;
}
