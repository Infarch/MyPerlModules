package Company2;
use strict;

use open qw(:std :utf8);

use Carp;

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my $self  = {
	  newitems => [],
	  @_ # init
  };
  return bless($self, $class);
}

sub get_id_by_license {
	my ($self, $dbh, $license) = @_;
	my $sql = "select * from company where license=$license";
	my $sth = $dbh->prepare($sql);
	$sth->execute() or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish;
	return $row ? $row->{id} : undef;
}

# returns ID of the new company
sub insert {
	my ($self, $dbh, $full_name, $short_name, $license) = @_;
	
	# insert
	my $sth = $dbh->prepare("insert into company (name, short_name, license) values ('$full_name', '$short_name', $license);");
	$sth->execute() or	die "SQL Error: ".$dbh->err;
	$sth->finish();
	
	# get ID
	$sth = $dbh->prepare('select LAST_INSERT_ID() as id');
	$sth->execute() or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	my $id = $row->{id} or die "Error reading company id";
	$sth->finish();
	push @{ $self->{newitems} }, "insert into company (id, name, short_name, license) values ($id, '$full_name', '$short_name', $license);";
	return $id;
}

sub flush {
	my ($self, $filename) = @_;
	open (DEST, ">$filename")
		or die "Can not open $filename";
	foreach ( @{ $self->{newitems} } ){
		print DEST "$_\n";
	}
	close DEST;
}

1;
