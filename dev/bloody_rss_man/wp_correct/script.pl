use strict;
use warnings;

use DBI;
use SimpleConfig;


# several constants are defined here
my $table = 'wp_posts';
my $column_id = 'ID';
my $column_data = 'post_content';

my $replacement = $constants{General}{Replacement};


{
	no warnings 'prototype';
	main();
}


exit;

# ----------------------------------------------------------------

# the main function
sub main(){
	
	# get database handlers
	my $idbh = get_dbh();
	my $udbh = get_dbh();
	
	# get iterator
	my $getNext = get_iterator($idbh);
	
	my $count = 0;
	
	# loop through data
	while (defined (my $hashref = $getNext->())){
		
		if(do_replacement($hashref)){
			# update record if it was changed
			update_record($udbh, $hashref);
			$count++;
		}
		
	}
	
	print "Updated $count records\n";
	
	$udbh->disconnect();
}

# updates a database record
sub update_record {
	my ($dbh, $hashref) = @_;
	
	my $sql = "UPDATE $table SET $column_data=? WHERE $column_id=?";
	my $sth = $dbh->prepare($sql);
	my @vals = ($hashref->{$column_data}, $hashref->{$column_id});
	$sth->execute(@vals) or 
		die "SQL Error: ".$dbh->err()." ($sql)\n(@vals)\n";
		
	$sth->finish;
}

# replaces HREFs
sub do_replacement {
	my $hashref = shift;
	
	my $data = $hashref->{$column_data};
	
	my $count = $data =~ s/\bhref\s*=\s*('|").*?\1/href="$replacement"/isg; #'
	
	$hashref->{$column_data} = $data;
	
	return $count;
}

# returns an iterator for dataset
sub get_iterator {
	my $dbh = shift;
	my $stop = 0;

	# prepare the statement handler	
	my $sql = "SELECT $column_id, $column_data from $table";
	my $sth = $dbh->prepare($sql);
	$sth->execute() or 
		die "SQL Error: ".$dbh->err()." ($sql)\n";

	my $iterator = sub {
		# each call of the iterator causes fetching of a next record
		return undef if $stop;
		my $hash_ref = $sth->fetchrow_hashref;
		if (!$hash_ref) {
			# finish
			$sth->finish();
			$dbh->disconnect();
			$stop = 1;
			return undef;
		}
		return $hash_ref;
	};
	
	return $iterator;
}


# returns the database handler
sub get_dbh {
	
	my $database = $constants{General}{DB_NAME};
	my $host = $constants{General}{DB_HOST};
	my $user = $constants{General}{DB_LOGIN};
	my $pass = $constants{General}{DB_PASSWORD};
	
	
	my $dbh = DBI->connect("dbi:mysql:$database:host=$host", $user, $pass) or 
		die "Connection Error: $DBI::errstr\n";
		
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	
	return $dbh;
}
