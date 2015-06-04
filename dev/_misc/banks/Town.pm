package Town;
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

sub get_type_id {
	my ($self, $dbh, $name) = @_;
	my $sql = "select id from class_town where name=N?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($name) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row ? $row->{id} : 0;
}

sub get_by_id {
	my ($self, $dbh, $id) = @_;
	my $sql = "select * from town where id=?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($id) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}

sub search {
	my ($self, $dbh, $name, $type) = @_;
	my $where = 'where name=N?';
	if(defined $type){
		$where .= " and class_town_id = $type";
	}
	my $sql = "select * from town $where";
	my $sth = $dbh->prepare($sql);
	$sth->execute($name) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}


# also creates a new database record if there is no town
sub insert {
	my ($self, $dbh, $name, $type, $region_id) = @_;
	
	my $sth = $dbh->prepare("insert into town(name, class_town_id, region_id) values (?, ?, ?)");
	$sth->execute($name, $type, $region_id) or	die "SQL Error: ".$dbh->err;

	# get back
	my $select = "select id from town where name=N? and class_town_id=? and region_id=?";
	$sth = $dbh->prepare($select);
	$sth->execute($name, $type, $region_id) or	die "SQL Error: ".$dbh->err;
	my $row = $sth->fetchrow_hashref() or die 'Error reading new town id';
	my $id = $row->{id};
	$sth->finish();
	push @{ $self->{newitems} }, "insert into town(id, name, class_town_id, region_id) values ($id, '$name', $type, $region_id);";
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
