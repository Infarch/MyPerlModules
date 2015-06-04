package Feature;

use strict;
use warnings;


# base class
use base qw(ISoft::DB ISoft::ClassExtender);

our $BIGNUM = 999999.00;

our $TYPE_CHECKBOX_SINGLE   = 'C';
our $TYPE_CHECKBOX_MULTIPLE = 'M';
our $TYPE_SELECT_TEXT       = 'S';
our $TYPE_SELECT_NUMBER     = 'N';
our $TYPE_OTHER_TEXT        = 'T';
our $TYPE_OTHER_NUMBER      = 'O';
our $TYPE_OTHER_DATE        = 'D';
our $TYPE_OTHER_RANGE       = 'R';

our $CST_FEATURE = 'cscart_product_features';
our $CST_FEATURE_DESCRIPTION = 'cscart_product_features_descriptions';

our $CST_FILTER = 'cscart_product_filters';
our $CST_FILTER_DESCRIPTION = 'cscart_product_filter_descriptions';

our $CST_FILTER_RANGE = 'cscart_product_filter_ranges';
our $CST_FILTER_RANGE_DESCRIPTION = 'cscart_product_filter_ranges_descriptions';

our $CST_SHARING = 'cscart_ult_objects_sharing';



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'Feature',
	  namecolumn => 'Name',
	  @_ # init
  );
  
  $self{Columns} = {
  	ID     => { Type => $ISoft::DB::TYPE_INT,     NotNull => 1, PrimaryKey => 1 },
  	Name   => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 100 },
  	Prefix => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 100 },
  	Suffix => { Type => $ISoft::DB::TYPE_VARCHAR, NotNull => 1, Length => 100 },
  	Type   => { Type => $ISoft::DB::TYPE_CHAR,    NotNull => 1, Length => 1 },
  	CartID => { Type => $ISoft::DB::TYPE_INT,     NotNull => 1 },
  };
  
  my $self = bless(\%self, $class);
  
  return $self;
}

sub is_numberic {
	my $type = shift;
	return ($type eq $TYPE_OTHER_NUMBER || $type eq $TYPE_SELECT_NUMBER || $type eq $TYPE_OTHER_RANGE);
}

sub get_feature_type {
	my($tag, $multi) = @_;
	
	if($multi){
		return $TYPE_CHECKBOX_MULTIPLE;
	}
	
	if($tag eq 'integer'){
		return $TYPE_OTHER_NUMBER;
	} elsif($tag eq 'real'){
		return $TYPE_OTHER_RANGE;
	} elsif($tag eq 'range'){
		return $TYPE_OTHER_RANGE;
	} elsif($tag eq 'string'){
		return $TYPE_SELECT_TEXT;
	} elsif($tag eq 'checkbox'){
		return $TYPE_CHECKBOX_SINGLE;
	} else {
		die "unknown tag $tag";
	}
	
}

sub get_next_feature_position {
	my ($dbh) = @_;
	
	my $position = ISoft::DB::do_query($dbh, sql=>"select max(`position`) from `$CST_FEATURE`", single=>1) || 0;
	return $position;
	
}

sub get_next_filter_position {
	my ($dbh) = @_;
	
	my $position = ISoft::DB::do_query($dbh, sql=>"select max(`position`) from `$CST_FILTER`", single=>1) || 0;
	return $position;
	
}

# inserts the feature (actually, feature+description, two tables) into cscart table.
sub csInsertFeature {
	my($self, $dbh, $scripts) = @_;
	
	my @slist;
	
	my $type = $self->get('Type');
	my $name = $self->Name();
	my $pre = $self->get("Prefix");
	my $suf = $self->get("Suffix");
	
	# insert a new feature
	my $position = get_next_feature_position($dbh);
	my $sql = "insert into `$CST_FEATURE` (`company_id`,`feature_type`,`parent_id`,`display_on_product`,`display_on_catalog`,`status`,`position`,`comparison`,`categories_path`) values (?,?,?,?,?,?,?,?,?);";
	my @args = (1, $type, 0, 1, 0, 'A', $position, 'Y', '');
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
	my $new_id = ISoft::DB::do_query($dbh, sql=>'select LAST_INSERT_ID()', single=>1);
	$self->set('CartID', $new_id);
	
	push @$scripts, "insert into `$CST_FEATURE` (`feature_id`, `company_id`,`feature_type`,`parent_id`,`display_on_product`,`display_on_catalog`,`status`,`position`,`comparison`,`categories_path`) values ($new_id,1,'$type',0,1,0,'A',$position,'Y','');";
	push @$scripts, "insert into `$CST_SHARING` (`share_company_id`,`share_object_id`,`share_object_type`) values (1,'$new_id','product_features');";
	
	# insert descriptions
	$sql = "insert into `$CST_FEATURE_DESCRIPTION` (`feature_id`,`description`,`full_description`,`prefix`,`suffix`,`lang_code`) values (?,?,?,?,?,?);";
	@args = ($new_id, $self->Name, '', $pre, $suf, 'EN');
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);	
	$args[$#args] = 'RU';
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);

	push @$scripts, "insert into `$CST_FEATURE_DESCRIPTION` (`feature_id`,`description`,`full_description`,`prefix`,`suffix`,`lang_code`) values ($new_id,'$name','','$pre','$suf','EN');";	
	
	push @$scripts, "insert into `$CST_FEATURE_DESCRIPTION` (`feature_id`,`description`,`full_description`,`prefix`,`suffix`,`lang_code`) values ($new_id,'$name','','$pre','$suf','RU');";	

}

sub csInsertFilter {
	my ($self, $dbh, $scripts) = @_;
	
	my $name = $self->Name();
	my $feature_id = $self->get('CartID');
	
	my $position = get_next_filter_position($dbh);
	my $sql = "insert into `$CST_FILTER` (`company_id`,`feature_id`,`position`,`show_on_home_page`,`status`,`round_to`,`display`,`display_count`,`categories_path`) values (?,?,?,?,?,?,?,?,?);";
	my @args = (1, $feature_id, $position, 'Y', 'A', 1, 'Y', 10, '');
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
	my $filter_id = ISoft::DB::do_query($dbh, sql=>'select LAST_INSERT_ID()', single=>1);
	
	push @$scripts, "insert into `$CST_FILTER` (`company_id`,`feature_id`,`position`,`show_on_home_page`,`status`,`round_to`,`display`,`display_count`,`categories_path`) values (1,$feature_id,$position,'Y','A',1,'Y',10,'');";
	push @$scripts, "insert into `$CST_SHARING` (`share_company_id`,`share_object_id`,`share_object_type`) values (1,'$filter_id','product_filters');";
	
	# filter descriptions
	$sql = "insert into `$CST_FILTER_DESCRIPTION` (filter_id, filter, lang_code) values (?,?,?);";
	@args = ($filter_id, $name, 'EN');
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);	
	$args[$#args] = 'RU';
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
	
	push @$scripts, "insert into `$CST_FILTER_DESCRIPTION` (filter_id, filter, lang_code) values ($filter_id,'$name','EN');";
	push @$scripts, "insert into `$CST_FILTER_DESCRIPTION` (filter_id, filter, lang_code) values ($filter_id,'$name','RU');";
	
	return $filter_id;
	
}

sub csCreateFilterRange {
	my ($self, $dbh, $filter_id, $from, $to, $position, $scripts) = @_;
	
	my $feature_id = $self->get('CartID');
	$to ||= $BIGNUM;
	
	my $sql = "insert into `$CST_FILTER_RANGE` (`feature_id`,`filter_id`,`from`,`to`,`position`) values (?,?,?,?,?);";
	my @args = ($feature_id, $filter_id, $from, $to, $position);
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
	my $range_id = ISoft::DB::do_query($dbh, sql=>'select LAST_INSERT_ID()', single=>1);
	
	push @$scripts, "insert into `$CST_FILTER_RANGE` (`range_id`,`feature_id`,`filter_id`,`from`,`to`,`position`) values ($range_id,$feature_id,$filter_id,$from,$to,$position);";
	
	# descriptions
	my $rname;
	if($from == $to){
		$rname = $to . ' ' . $self->get('Suffix');
	} elsif ($to == $BIGNUM){
		$rname = $from . ' ' . $self->get('Suffix') . ' and Above';
	} else {
		$rname = "$from - $to " . $self->get('Suffix');
	}
	
	$sql = "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values (?,?,?);";
	@args = ($range_id, $rname, 'EN');
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);	
	$args[$#args] = 'RU';
	ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
	
	push @$scripts, "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values ($range_id,'$rname','EN');";
	push @$scripts, "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values ($range_id,'$rname','RU');";
	
}

sub createFilterRanges {
	my ($self, $dbh, $filter_id, $from, $rangelength, $count, $scripts) = @_;
	
	my $feature_id = $self->get('CartID');
	my $position = 0;
	
	while($count--){
		my $limit = $from + $rangelength - 1;
		my $rname = "$from - $limit";
		
		my $sql = "insert into `$CST_FILTER_RANGE` (`feature_id`,`filter_id`,`from`,`to`,`position`) values (?,?,?,?,?);";
		my @args = ($feature_id, $filter_id, $from, $limit, $position);
		ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
		my $range_id = ISoft::DB::do_query($dbh, sql=>'select LAST_INSERT_ID()', single=>1);
		
		push @$scripts, "insert into `$CST_FILTER_RANGE` (`range_id`,`feature_id`,`filter_id`,`from`,`to`,`position`) values ($range_id,$feature_id,$filter_id,$from,$limit,$position);";
		
		# descriptions
		$sql = "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values (?,?,?);";
		@args = ($range_id, $rname, 'EN');
		ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);	
		$args[$#args] = 'RU';
		ISoft::DB::do_query($dbh, sql=>$sql, values=>\@args);
		
		push @$scripts, "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values ($range_id,'$rname','EN');";
		push @$scripts, "insert into `$CST_FILTER_RANGE_DESCRIPTION` (`range_id`,`range_name`,`lang_code`) values ($range_id,'$rname','RU');";
		
		$from = $limit + 1;
		$position++;
	}
	
}


sub prepareEnvironment {
	my ($self, $dbh) = @_;
	my $sql = $self->buildTableSql();
	ISoft::DB::do_query($dbh, sql=>$sql);
}



1;
