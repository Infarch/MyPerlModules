package Street;
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

#sub get_type_id {
#	my ($self, $dbh, $name) = @_;
#	my $sql = "select id from class_town where name=N?";
#	my $sth = $dbh->prepare($sql);
#	$sth->execute($name) or	die "SQL Error: ".$dbh->err;
#	my $row = $sth->fetchrow_hashref();
#	$sth->finish();
#	return $row ? $row->{id} : 0;
#}


sub search_by_name {
	my ($self, $dbh, $name) = @_;
	my $sql = "select * from street where name=N?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($name) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}

sub search_by_name_type {
	my ($self, $dbh, $name, $type) = @_;
	my $sql = "select * from street where name=N? and class_street_id=?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($name, $type) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}

sub get_type_id {
	my ($self, $dbh, $name) = @_;
	my $sql = 'select id from class_street where name=N?';
	my $sth = $dbh->prepare($sql);
	$sth->execute($name) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref() or die "No street type $name";
	$sth->finish();
	return $row->{id};
}

sub insert {
	my ($self, $dbh, $name, $type) = @_;
	
	my $sth = $dbh->prepare("insert into street(name, class_street_id) values (?, ?)");
	$sth->execute($name, $type) or	die "SQL Error: ".$dbh->err;

	# get back
	my $select = "select id from street where name=N? and class_street_id=?";
	$sth = $dbh->prepare($select);
	$sth->execute($name, $type) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref() or die 'Error reading new street id';
	$sth->finish();
	my $id = $row->{id};
	push @{ $self->{newitems} }, "insert into street(id, name, class_street_id) values ($id, '$name', $type);";
	return $row->{id};
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
