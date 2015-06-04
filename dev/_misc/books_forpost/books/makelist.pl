use strict;
use warnings;

use lib '/work/perl_lib';

use ISoft::DBHelper;



# get handler
my $dbh = get_dbh();


# get categories
my $sql = 'select razd_en, razd_ru from razdel';
my $rows = do_query($dbh, sql=>$sql);

# convert to hash ru=>en
my %categories = map { $_->{razd_ru} => $_->{razd_en} } @$rows;

# get books
$sql = 'select Razdel, Name_file, Size from books';
$rows = do_query($dbh, sql=>$sql);


# make list
open LIST, '>list.txt';
foreach my $book (@$rows){
	my $c = $categories{$book->{Razdel}};
	print "xx\n" unless $c;
	print LIST "$c $book->{Name_file} $book->{Size}\n";
}
close LIST;












release_dbh($dbh);
























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


