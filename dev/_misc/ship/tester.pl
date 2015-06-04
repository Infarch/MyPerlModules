use strict;
use warnings;

use threads;

use Thread::Queue;

use Parser;

use DBI;

my $dbh = get_dbh();
my $parser = new Parser($dbh);

# the parser now works in 'insert' mode
# use: my $parser = new Parser($dbh, update=>1);
# or
# $parser->update(1)
# for activating 'update' mode.

my @rangelist = $parser->getImoRangeLinks();
my @rslist;
foreach (@rangelist){
	push @rslist, $parser->getRsFromImoRange($_);
}

foreach (@rslist){
	$parser->process_rs($_);
}


exit;


sub get_dbh {
	my $dbfile = 'utf3.db';
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","",{ RaiseError => 1 }) or die $DBI::errstr;
	$dbh->{sqlite_unicode} = 1;
	$dbh->{AutoCommit} = 1;
	return $dbh;
}