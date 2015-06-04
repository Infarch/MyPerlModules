use strict;
use warnings;


use DBI;

use Encode 'encode';

my $dbh = get_dbh();

my $field = "name_ru";

#my $sql = "select ProductID, slug from SC_products";
my $sql = qq(
	select productID as ID, $field as xxx from SC_products ss where
		(select count(*) from `sc_products` sc where ss.$field=sc.$field)>1 and $field!=''
	order by $field
);

my $rows = do_query($dbh, sql=>$sql);

print scalar @$rows, "\n\n";

my @slist;

my $oldvalue = '';
my $counter;
foreach my $row (@$rows){
	my $val = $row->{xxx};
	if($oldvalue ne $val){
		$oldvalue = $val;
		$counter = 2;
		next;
	}
	
	my $id = $row->{ID};
	
	my $new_val = "${val} $counter";
	while(field_exists($dbh, $new_val)){
		$counter++;
		$new_val = "${val} $counter";
	}
	$new_val =~ s/'/''/g; #'
	
	push @slist, "update SC_products set $field='$new_val' where ProductID=$id;";
	$counter++;
}

open SQL, '>sql.txt';
foreach my $ss (@slist){
	print SQL encode('cp1251',$ss), "\n";
}
close SQL;






exit;

sub field_exists {
	my ($dbh, $val) = @_;
	my $sql = "select count(*) from SC_products where $field=?";
	my $x = do_query($dbh, sql=>$sql, single=>1, values=>[$val]);
	return $x>0;
}

sub get_dbh {
	my $dbh = DBI->connect("dbi:mysql:test:host=localhost", 'root', 'admin') or 
		die "Connection Error: $DBI::errstr\n";
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	return $dbh;
}

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
