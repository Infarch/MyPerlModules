package ISoft::DB;

use strict;
use warnings;
use threads;
use threads::shared;

# general modules
use DBI;
use Error ':try';

# my modules
use ISoft::Exception::DB;
use ISoft::Exception::DB::ValidationError;
use ISoft::Exception::ScriptError;


# Define sql type constants
$ISoft::DB::TYPE_INT = 1;
$ISoft::DB::TYPE_TINYINT = 2;
$ISoft::DB::TYPE_SMALLINT = 3;
$ISoft::DB::TYPE_BIT = 4;
$ISoft::DB::TYPE_REAL = 5;
$ISoft::DB::TYPE_MONEY = 6;

$ISoft::DB::TYPE_CHAR = 9;
$ISoft::DB::TYPE_VARCHAR = 10;
$ISoft::DB::TYPE_TEXT = 11;
$ISoft::DB::TYPE_LONGTEXT = 12;

$ISoft::DB::TYPE_DATE = 15;

# a false validator always returning TRUE
sub is_valid_always {
	return 1;
}

sub is_valid_int {
	my ($val, $column) = @_;
	if(!$column->{NotNull} && !defined $val){
		return 1;
	}
	return $val =~ /^[-]?\d+$/;
}

sub is_valid_bit {
	my ($val, $column) = @_;
	if(!$column->{NotNull} && !defined $val){
		return 1;
	}
	return $val =~ /^[10]$/;
}

sub is_valid_float {
	my ($val, $column) = @_;
	if(!$column->{NotNull} && !defined $val){
		return 1;
	}
	return $val =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/;
}

sub is_valid_varchar {
	my ($val, $column) = @_;
	if($column->{NotNull} && !defined $val){
		return 0;
	}
	if(my $length = $column->{Length}){
		return $length >= length $val;
	}
	return 1;
}

sub is_valid_tinyint {
	my ($val, $column) = @_;
	if(!$column->{NotNull} && !defined $val){
		return 1;
	}
	my ($min, $max);
	if($column->{Unsigned}){
		$min = 0;
		$max = 255;
	} else {
		$min = -128;
		$max = 127;
	}
	return is_valid_int($val) && $val>=$min && $val<=$max;
}

sub is_valid_smallint {
	my ($val, $column) = @_;
	if(!$column->{NotNull} && !defined $val){
		return 1;
	}
	my ($min, $max);
	if($column->{Unsigned}){
		$min = 0;
		$max = 65535;
	} else {
		$min = -32768;
		$max = 32767;
	}
	return is_valid_int($val) && $val>=$min && $val<=$max;
}

sub get_validator {
	my $type = shift;
	return
		$type == $ISoft::DB::TYPE_INT ? \&is_valid_int :
		($type == $ISoft::DB::TYPE_REAL) || ($type == $ISoft::DB::TYPE_MONEY) ? \&is_valid_float :
		$type == $ISoft::DB::TYPE_BIT ? \&is_valid_bit :
		($type == $ISoft::DB::TYPE_VARCHAR || $type == $ISoft::DB::TYPE_CHAR) ? \&is_valid_varchar :
			\&is_valid_always;
}

sub maxReturn {
	my ($self, $top) = @_;
	$self->{top} = $top;
}

sub tablename {
	my $object = shift;
	return $object->{tablename};
}

sub get_dbh_mysql {
	my ($database, $user, $pass, $host) = @_;
	$host = $host || 'localhost';
	my $dbh = DBI->connect("dbi:mysql:$database:host=$host", $user, $pass) or 
		throw ISoft::Exception::DB(message=>"Connection Error: $DBI::errstr\n");
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	$dbh->{AutoCommit} = 0;
	return $dbh;
}


# auxiliary function generating sql query for selecting row(s).
# returns both sql script and array of values to be used for the selection
sub _make_select_clause {
	my ($object, %params) = @_;

	my $tbname = $object->tablename();

	# which columns are set
	my @selectValues;
	my @selectClauses;
	my @items = keys( %{$object->{Columns}} );
	foreach my $columnname (@items) {

		my $type = $object->{Columns}->{$columnname}->{Type};

		next if($type == $ISoft::DB::TYPE_TEXT);
		next if($type == $ISoft::DB::TYPE_LONGTEXT);
		
		next unless $object->isUpdated($columnname);

		my $value = $object->{Columns}->{$columnname}->{Value};
		my $operator = $object->{Columns}->{$columnname}->{Operator} || '=';

		my $validator = get_validator($type);

		if ( ! defined $value) {
			# ... is [not] null
			if($operator eq '='){
				# default operator does not make sense for null values, change to IS
				$operator = 'IS';
			}
			push @selectClauses, "`$columnname` $operator null";
			#push @selectValues, $value;
		}

		elsif (ref $value && ref $value eq 'ARRAY'){

			my @placeholders;

			foreach my $item (@$value){
				unless($validator->($item, $object->{Columns}->{$columnname})){
					throw ISoft::Exception::DB::ValidationError(message=>"'$item' could not be validated for column $columnname in $tbname");
				}
				push @placeholders, '?';
				push @selectValues, $item;
			}
			my $holdstr = join ',', @placeholders;
			if($operator eq '='){
				# default operator does not make sense for list of values, change to IN
				$operator = 'IN';
			}
			push @selectClauses, "`$columnname` $operator ($holdstr)";
		}

		else {
			unless($validator->($value, $object->{Columns}->{$columnname})){
				throw ISoft::Exception::DB::ValidationError(message=>"'$value' could not be validated for column $columnname in $tbname");
			}
			push @selectClauses, "`$columnname` $operator ?";
			push @selectValues, $value;
		}
	}

	
	my $clause = '';
	
	if( @selectClauses > 0 ) {
		$clause  = join " AND ", @selectClauses;
		$clause .= ' ';
	}

	# are we to add a special where clause
	if(defined($object->{Where})) {
		my $where = $object->{Where};
		$clause .= " $where";
	}
	
	# Protest if theres no select values - this is usually a mistake
	if($clause eq '') {
		throw ISoft::Exception::ScriptError(message=>"Invalid statement - No select values in $tbname");
	}

	my $limit = '';
	if ($object->{top}){
		$limit = 'limit '.$object->{top};
	}

	my $selector = $params{count} ? 'count(*)' : '*';


	# order
	my $order = '';
	if(defined $object->{Orders}){
		my @orders = @{ $object->{Orders} };
		if(@orders>0){
			$order = 'ORDER BY ' . join ', ', @orders;
		}
	}
	my $sql = "Select $selector FROM `$tbname` WHERE $clause $limit $order";

	return ($sql, \@selectValues);
}

sub where {
	my ($obj, $clause) = @_;
	throw ISoft::Exception::ScriptError(message=>"Invalid where clause") unless $clause;
	$obj->{Where} = $clause;
	return $obj;
}

# UNSAFE method!!!
# Allows to delete more than one database record.
# Use 'delete' method instead if you want to be sure that all your data will not be lost!!!
sub deleteHeavy {
	my ($object, $dbh) = @_;
	my $tbname = $object->tablename();
	# which columns are set
	my @whereColumns;
	my @whereValues;
	my @items = keys( %{$object->{Columns}} );
	foreach my $columnname (@items) {
		my $type = $object->{Columns}->{$columnname}->{Type};
		my $validator = get_validator($type);
		my $value = $object->{Columns}->{$columnname}->{Value};
		if((defined $value) && !$validator->($value, $object->{Columns}->{$columnname})){
			throw ISoft::Exception::DB::ValidationError(message=>"'$value' could not be validated for column $columnname in $tbname");
		}
		next unless $object->{Columns}->{$columnname}->{PrimaryKey};
		push @whereColumns, "$columnname=?";
		push @whereValues, $value;
	}
	# Protest if there are no 'where' values
	if(@whereValues==0) {
		throw ISoft::Exception::ScriptError(message=>"Invalid statement - No where values in $tbname");
	}
	my $where_columns = join ' and ', @whereColumns;
	my $sql = "Delete from $tbname where $where_columns";
	do_query($dbh, sql=>$sql, values=>\@whereValues);
	return 1;
}

sub delete {
	my ($object, $dbh) = @_;
	my $tbname = $object->tablename();
	# which columns are set
	my @whereColumns;
	my @whereValues;
	my @items = keys( %{$object->{Columns}} );
	foreach my $columnname (@items) {
		next unless $object->{Columns}->{$columnname}->{PrimaryKey};
		my $type = $object->{Columns}->{$columnname}->{Type};
		my $validator = get_validator($type);
		my $value = $object->{Columns}->{$columnname}->{Value};
		if((defined $value) && !$validator->($value, $object->{Columns}->{$columnname})){
			throw ISoft::Exception::DB::ValidationError(message=>"'$value' could not be validated for column $columnname in $tbname");
		}
		push @whereColumns, "$columnname=?";
		push @whereValues, $value;
	}
	# Protest if there are no 'where' values
	if(@whereValues==0) {
		throw ISoft::Exception::ScriptError(message=>"Invalid statement - No where values in $tbname");
	}
	my $where_columns = join ' and ', @whereColumns;
	my $sql = "Delete from $tbname where $where_columns";
	do_query($dbh, sql=>$sql, values=>\@whereValues);
	return 1;
}

sub update {
	my ($object, $dbh) = @_;
	my $tbname = $object->tablename();
	# which columns are set
	my @updateColumns;
	my @updateValues;
	my @whereColumns;
	my @whereValues;
	my @items = keys( %{$object->{Columns}} );
	foreach my $columnname (@items) {
		
		next if !$object->{Columns}->{$columnname}->{PrimaryKey} && !$object->isUpdated($columnname);
		
		my $type = $object->{Columns}->{$columnname}->{Type};
		my $validator = get_validator($type);
		my $value = $object->{Columns}->{$columnname}->{Value};
		
		if((defined $value) && !$validator->($value, $object->{Columns}->{$columnname})){
			throw ISoft::Exception::DB::ValidationError(message=>"'$value' could not be validated for column $columnname in $tbname");
		}
		if ($object->{Columns}->{$columnname}->{PrimaryKey}){
			push @whereColumns, "`$columnname`=?";
			push @whereValues, $value;
			next;
		}
		next unless $object->isUpdated($columnname);
		push @updateColumns, "`$columnname`=?";
		push @updateValues, $value;
	}
	# Protest if there are no 'where' values
	if(@whereValues==0) {
		throw ISoft::Exception::ScriptError(message=>"Invalid statement - No where values in $tbname");
	}
	# Protest if there are no update values
	if(@updateValues==0) {
		throw ISoft::Exception::ScriptError(message=>"Invalid statement - No update values in $tbname");
	}
	my $update_columns = join ',', @updateColumns;
	my $where_columns = join ' and ', @whereColumns;
	my $sql = "Update `$tbname` set $update_columns where $where_columns";
	my @values = (@updateValues, @whereValues);
	do_query($dbh, sql=>$sql, values=>\@values);
	return 1;
}

sub checkExistence {
	my($object, $dbh) = @_;
	return $object->select($dbh, 1);
}

sub selectCount {
	my ($object, $dbh) = @_;

	my ($sql, $values_ref) = _make_select_clause($object, count=>1);
	my $count = do_query($dbh, sql=>$sql, values=>$values_ref, single=>1);
	
	return $count;
}

sub select {
	my($object, $dbh, $allow_empty) = @_;

	my ($sql, $values_ref) = _make_select_clause($object);

	# for debugging
	my @selectValues = @$values_ref;
	$object->{Sql} = $sql;
	
	# get row data
	my @rows = do_query($dbh, sql=>$sql, values=>$values_ref);
	if (@rows==1){
		my $hash_ref = $rows[0];
		my @items = keys( %{$object->{Columns}} );
		foreach my $columnname (@items)  {
			$object->{Columns}->{$columnname}->{Value} = $hash_ref->{$columnname};
			$object->{Columns}->{$columnname}->{Updated} = 0;
		}
		return 1;
	} elsif (@rows>1){
		throw ISoft::Exception::ScriptError(message=>"Query $sql\n(@selectValues)\nreturned more than one row. Use listSelect method instead");
	} elsif(!$allow_empty) {
		throw ISoft::Exception::ScriptError(message=>"Empty resultset:\n$sql\n(@selectValues)\n");
	}

	return 0;
}

# don't select the big amount of data at once! 
sub selectAll {
	my($object, $dbh) = @_;

	my $limit = '';
	if ($object->{top}){
		$limit = 'limit '.$object->{top};
	}

	my $tbname = $object->tablename();
	my $sql = "Select * from `$tbname` $limit";
	
	# for debugging
	$object->{Sql} = $sql;

	# get row data
	my $rows_ref = do_query($dbh, sql=>$sql);
	my $casted = $object->castRows($rows_ref);
	return wantarray ? @$casted : $casted;
}

sub listSelect {
	my($object, $dbh) = @_;

	my ($sql, $values_ref) = _make_select_clause($object);
	
	# for debugging
	my @selectValues = @$values_ref; 
	$object->{Sql} = $sql;

	# get row data
	my $rows_ref = do_query($dbh, sql=>$sql, values=>$values_ref);
	my $casted = $object->castRows($rows_ref);
	return wantarray ? @$casted : $casted;
}

sub Name {
	my ($object, %params) = @_;
	my $namecolumn = exists $params{namecolumn} ? $params{namecolumn} : exists $object->{namecolumn} ? $object->{namecolumn} : undef;
	my $namepattern = exists $params{namepattern} ? $params{namepattern} : exists $object->{namepattern} ? $object->{namepattern} : undef;
	if(!$namecolumn && !$namepattern) {
		throw ISoft::Exception::ScriptError(message=>"No name column or pattern defined, set \$class->{namecolumn} or \$class->{namepattern} on " . $object->tablename());
	}
	if(defined $namecolumn ) {
		return $object->get($namecolumn);
	} elsif(defined $namepattern ) {
		# Replace -!ColumnName!- with ColumnName's value in pattern text
		my $pattern = $namepattern;
		while($pattern =~ /-!([\w\d_]+)!-/) {
			my $value = $object->get($1);
			$pattern =~ s/-!$1!-/$value/;
		}
		return $pattern;
	}
}

sub ID {
	my $self = shift;
	my $idfield = 'ID';
	if (exists $self->{idcolumn} && defined $self->{idcolumn}){
		$idfield = $self->{idcolumn};
	}
	my $id = $self->get($idfield);
	throw ISoft::Exception::ScriptError(message=>"$idfield is not defined")
		unless defined $id;
	return $id;
}

# Takes a rowlist (e.g. from a SELECT * query) and turns them into DB_* objects.
# Usage: my @obj_list = DB_Category->castRows(\@rows);
sub castRows {
	my ($class, $rows) = @_;
	my @objects;
	foreach my $row (@{$rows}) {
		my $object = $class->new();
		foreach my $columnname (keys %{$object->{Columns}}) {
			$object->{Columns}->{$columnname}->{Value} = $row->{$columnname};
		}
		push @objects, $object;
	}
	return wantarray ? @objects : \@objects;
}

sub setByHash {
	my ($self, $hash_ref) = @_;
	while (my ($key, $value) = each %$hash_ref){
		$self->set($key, $value);
	}
	return $self;
}

sub setKeysByObject {
	my ($self, $object) = @_;

	my $keys_set = 0;
	while(my ($column, $def) = each %{$self->{Columns}}) {
		if((defined $def->{ForeignTable}) && ($def->{ForeignTable} eq $object->tablename())) {
			$self->set($column, $object->get($def->{ForeignKey}));
			$keys_set++;
		}
	}
	if($keys_set == 0) {
		my $tbname1 = $self->tablename();
		my $tbname2 = $object->tablename();
		throw ISoft::Exception::ScriptError(message=>"No foreign key relationship between $tbname1 and $tbname2");
	}
}

# may be deprecated
sub convertFloat {
	my $value = shift;
	return undef if !defined $value;
	if($value =~ /^[-]?(\d+\.)*\d+(,\d{1,2}){1}$/) {			# Danish notation, 100.000,50
		$value =~ s/\.//g;
		$value =~ s/,/\./g;
	} elsif($value =~ /^[-]?(\d+,)*\d+(\.\d{1,2}){1}$/) {		# English notation 100,000.50
		$value =~ s/,//g;
	}
	return $value;
}

# may be deprecated
sub undefcmp {
	my ($a,$b) = @_;
	return  (!defined $a && !defined $b) ?  0 :
			( defined $a && !defined $b) ?  1 :
			(!defined $a &&  defined $b) ? -1 : undef;
}

sub isUpdated {
	my($self, $columnname) = @_;
	return $self->{Columns}->{$columnname}->{Updated};
}

sub setOperator {
	my($self, $columnname, $operator) = @_;
	throw ISoft::Exception::ScriptError(message=>"No column $columnname")
		unless exists $self->{Columns}->{$columnname};
	$self->{Columns}->{$columnname}->{Operator} = $operator;
	return $self;
}

sub setOrder {
	my($self, $columnname, $order) = @_;

	$order = lc $order;
	
	throw ISoft::Exception::ScriptError(message=>"No column $columnname")
		unless exists $self->{Columns}->{$columnname};

	if($order ne 'asc' && $order ne 'desc'){

		throw ISoft::Exception::ScriptError(message=>"Wrong order value: '$order'");
		
	}

	unless(exists $self->{Orders}){
		$self->{Orders} = shared_clone([]);
	}
	
	push @{$self->{Orders}}, "$columnname $order";
	
	return $self;
}

sub get {
	my ($self, $columnname) = @_;
	if(exists $self->{Columns}->{$columnname}){
		return $self->{Columns}->{$columnname}->{Value};
	} else {
		throw ISoft::Exception::ScriptError(message=>"Column $columnname does not exist in $self->{tablename}");
	}
}

sub set {
	my ($self, $columnname, $value, $operator) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"No column $columnname")
		unless exists $self->{Columns}->{$columnname};
	
	my $col = $self->{Columns}->{$columnname};
	
	if((ref $value) && (ref $value eq 'ARRAY')){
		$col->{Value} = shared_clone($value);
	} else {
		$col->{Value} = $value;
	}

	# We will not set not OldValue nor Changed flag since they look as unnecesary

	
#	# the value might be an array reference.
#	# we are using this approach for 'select' only so we don't need to perform any additional checking
#	if((ref $value) && (ref $value eq 'ARRAY')){
#		$col->{Value} = shared_clone($value);
#		$col->{Changed} = 1;
#	} else {
#		my $type = $col->{Type};
#		# Set oldvalue
#		if(defined($type) && ( $type == $ISoft::DB::TYPE_REAL || $type == $ISoft::DB::TYPE_MONEY) ) {
#			$self->{Columns}->{$columnname}->{OldValue} = convertFloat($col->{Value});
#		} else {
#			$self->{Columns}->{$columnname}->{OldValue} = $col->{Value};
#		}
#		# Set value
#		if(!defined($value)) {
#			$self->{Columns}->{$columnname}->{Value} = undef;
#		}	else {
#			if(defined($type) && ( $type == $ISoft::DB::TYPE_REAL || $type == $ISoft::DB::TYPE_MONEY) ) {
#				$self->{Columns}->{$columnname}->{Value} = convertFloat($value);
#			} else {
#				$self->{Columns}->{$columnname}->{Value} = $value;
#			}
#		}
#		# Set changed bit
#		my ($newval, $oldval) = ($col->{Value}, $col->{OldValue});
#		if (defined $type) {
#			if( !defined $newval || !defined $oldval ) {
#				# Comparing mixed undef
#				$self->{Columns}->{$columnname}->{Changed} = abs(undefcmp($newval,$oldval));
#			} elsif( $type == $ISoft::DB::TYPE_REAL || $type == $ISoft::DB::TYPE_MONEY || $type == $ISoft::DB::TYPE_INT) {
#				# Compare numbers
#				$self->{Columns}->{$columnname}->{Changed} = abs($newval <=> $oldval);
#			} else {
#				# Compare everything else
#				$self->{Columns}->{$columnname}->{Changed} = abs($newval cmp $oldval);
#			}
#		}
#	}
	
	$self->{Columns}->{$columnname}->{Updated} = 1;
	
	if(defined $operator){
		$self->setOperator($columnname, $operator);
	}
	
	return $self;
}

sub setAll {
	my $self = shift;
	foreach my $columnname ( keys %{$self->{Columns}} )  {
		next if($columnname eq 'ID');
		next unless defined($self->{Columns}->{$columnname}->{Value});
		$self->{Columns}->{$columnname}->{Updated} = 1;
	}
}

sub insert {
	my($object, $dbh, $quick) = @_;
	my $tbname = $object->tablename();
	my @items = keys( %{$object->{Columns}} );
	my @name;
	my @value;
	my @placeholders;
	foreach my $columnname (@items)  {
		next if exists($object->{Columns}->{$columnname}->{PrimaryKey});
		next unless $object->{Columns}->{$columnname}->{Updated};
		my $type = $object->{Columns}->{$columnname}->{Type};
		my $validator = get_validator($type);
		my $value = $object->{Columns}->{$columnname}->{Value};
		if((defined $value) && !$validator->($value, $object->{Columns}->{$columnname})){
			throw ISoft::Exception::DB::ValidationError(message=>"'$value' could not be validated for column $columnname in $tbname");
		}
		push @name, "`$columnname`";
		push @value, $value;
		push @placeholders, '?';
	}
	if(@name==0) {
		throw ISoft::Exception::ScriptError(message=>"Nothing to insert into $tbname");
	}
	my $names = join',', @name;
	my $hold_str = join ',', @placeholders;
	do_query($dbh, sql=>"insert into `$tbname` ($names) values ($hold_str)", values=>\@value);
	# retrieve the data back
	if( !$quick ) {
		my $new_id = do_query($dbh, sql=>'select LAST_INSERT_ID()', single=>1);
		foreach my $columnname (@items)  {
			if(exists($object->{Columns}->{$columnname}->{PrimaryKey})) {
				$object->set($columnname, $new_id);
				last;
			}
		}
		$object->select($dbh);
	}
	return 1;
}

sub do_query {
	my $dbh = shift;
	my %params = @_;

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
			throw ISoft::Exception::ScriptError(message=>"The 'values' parameter should be an array reference");
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or 
			throw ISoft::Exception::DB(message=>"SQL Error: ".$dbh->err()." ($sql)\n", vals=>\@vals);
	} else {
		$sth->execute() or 
			throw ISoft::Exception::DB(message=>"SQL Error: ".$dbh->err()." ($sql)\n");
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
		return $rows->[0]->[0];
	}
	return wantarray ? @{$rows} : $rows;
}

# the function generates QSl for creating the table in database
sub buildTableSql {
	my $self = shift;
	
	my $tablename = $self->tablename();
	
	my @lines;
	
	my $column;
	my $data;
	
	my @columns = keys %{ $self->{Columns} };
	
	foreach my $column (@columns){
		
		my @additions;
		
		my $line = "`$column` ";
		
		my $data = $self->{Columns}->{$column};
		my $type = $data->{Type};
		my $unsigned = $data->{Unsigned} ? 'UNSIGNED ' : '';
		
		# type
		if($type==$ISoft::DB::TYPE_INT){
			$line .= "INT $unsigned";
		} elsif ($type==$ISoft::DB::TYPE_TINYINT) {
			$line .= "TINYINT $unsigned";
		} elsif ($type==$ISoft::DB::TYPE_SMALLINT) {
			$line .= "SMALLINT $unsigned";
		} elsif ($type==$ISoft::DB::TYPE_BIT) {
			$line .= "TINYINT ";
		} elsif ($type==$ISoft::DB::TYPE_REAL) {
			$line .= "FLOAT $unsigned";
		} elsif ($type==$ISoft::DB::TYPE_MONEY) {
			$line .= "FLOAT $unsigned";
		} elsif ($type==$ISoft::DB::TYPE_CHAR) {
			$line .= 'CHAR ';
		} elsif ($type==$ISoft::DB::TYPE_VARCHAR) {
			$line .= 'VARCHAR ';
		} elsif ($type==$ISoft::DB::TYPE_TEXT) {
			$line .= 'TEXT ';
		} elsif ($type==$ISoft::DB::TYPE_LONGTEXT) {
			$line .= 'LONGTEXT ';
		} elsif ($type==$ISoft::DB::TYPE_DATE) {
			$line .= 'DATE ';
		} else {
			throw ISoft::Exception::ScriptError(message=>"Unknown data type $type");
		}
		
		# length (if any)
		if(exists $data->{Length}){
			$line .= "($data->{Length}) ";
		}
		
		# nullable
		if($data->{NotNull}){
			$line .= "NOT NULL ";
		} else {
			$line .= "NULL ";
		}
	
		# default value
		my $default = '';
		if ($data->{PrimaryKey}){
			push @additions, "PRIMARY KEY (`$column`)";
			$default = 'AUTO_INCREMENT '
		} elsif(defined $data->{Unique}){
			push @additions, "UNIQUE INDEX `$column` (`$column`)";
		} elsif(defined $data->{Default}){
			$default = "DEFAULT '$data->{Default}'";
		}
		$line .= $default;
		
		# index / foreign key
		if(my $ftable = $data->{ForeignTable}){
			
			my $fkey = $data->{ForeignKey};
			throw ISoft::Exception::ScriptError(message=>"No foreign key for reference $tablename => $ftable") unless $fkey;
			
			my $fk = "FK_${tablename}_$ftable";
			push @additions, "INDEX `$fk` (`$column`)";
			push @additions, "CONSTRAINT `$fk` FOREIGN KEY (`$column`) REFERENCES `$ftable` (`$fkey`)";
			
		} elsif($data->{Index}){
			push @additions, "INDEX `$column` (`$column`)";
		}
		
		push @lines, $line;
		
		# add all additional lines
		push @lines, @additions;
	}
	
	my $sql = join ",\n", @lines;
	$sql = "CREATE TABLE IF NOT EXISTS `$tablename` (\n$sql\n) AUTO_INCREMENT=1";
	return $sql;
	
}








1;
