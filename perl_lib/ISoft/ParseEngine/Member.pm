package ISoft::ParseEngine::Member;

use threads;
use threads::shared;

use strict;
use warnings;

use Data::Dumper;
use Encode qw/encode decode/;
use HTML::TreeBuilder::XPath;
use HTTP::Request;
use URI;
use Digest::MD5 qw(md5_hex);

use ISoft::Exception::ScriptError;

# setup dumper
$Data::Dumper::Indent = 1;
$Data::Dumper::Pair = ':';
# a hack allowing to dump data in utf8
$Data::Dumper::Useqq = 1;
{
	no warnings 'redefine';
	sub Data::Dumper::qquote {
		my $s = shift;
		return "'$s'";
	}
}


# base class
use base qw(ISoft::DB ISoft::ClassExtender);

# status constants
use constant STATUS_NEW        => 1;
use constant STATUS_PROCESSING => 2; # deprecated, but...
use constant STATUS_DONE       => 3;
use constant STATUS_FAILED     => 4;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  tablename  => 'Member',
	  namecolumn => 'Name',
	  cache      => 1, # allows to cache http response for the member
	  debug      => 0,
	  @_ # init
  );
  
  my $snew = __PACKAGE__->STATUS_NEW;
  
  $self{Columns} = {
  	# the columns below are required for all members
  	ID     => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	URL    => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 500, NotNull => 1 },
  	#KeyURL => { Type => $ISoft::DB::TYPE_CHAR, Length => 32, Unique => 1 },
  	Status => { Type => $ISoft::DB::TYPE_TINYINT, NotNull => 1, Default => $snew, Index => 1 },
  	Errors => { Type => $ISoft::DB::TYPE_TINYINT, NotNull => 1, Default => 0 },
  };
  
  my $self = bless(shared_clone(\%self), $class);
  
  return $self;
}

sub cache { return $_[0]->_getset('cache', $_[1]); }

# some additional business logic for the URL field
sub setKeyURL {
	my ($self, $url) = @_;
	return $self->set('KeyURL', md5_hex($url));
}

# gets / sets the value of 'Debug' field.
# 1 in this field means that the object is in Debug mode:
# no database insert, echo to console.
# but only the programmer is responsible here.
sub debug {
	my ($self, $debug) = @_;
	my $val = $self->{debug};
	$self->{debug} = $debug if(defined $debug);
	return $val;
}

# converts a given url to absolute form using the current URL as base
sub absoluteUrl {
	my ($self, $url) = @_;
	
	return URI->new($url)->abs($self->get('URL'))->as_string;

}

sub asHtml {
	my ($self, $val) = @_;
	# $val should be an instance of HTML::Element
	return $val->as_HTML('<>&', '', {});
}

sub debugEcho {
	my ($self, $data) = @_;
	my $str;
	if (ref $data){
		$str = Dumper($data);
	} else {
		$str = $data;
	}
	$str = encode('cp866', $str);
	print "$str\n";
}

sub getWorkList {
	my ($self, $dbh, $limit) = @_;
	
	my $tmp_obj = $self->new;
	$tmp_obj->set('Status', $tmp_obj->STATUS_NEW);
	$tmp_obj->maxReturn($limit) if $limit;
	
	my $reff = $tmp_obj->listSelect($dbh);

	if(wantarray){
		return @$reff;
	} else {
		return $reff;
	}
	
}

sub removeColumn {
	my ($self, $name) = @_;
	throw ISoft::Exception::ScriptError(message=>"Column '$name' is not exist")
		if !exists $self->{Columns}->{$name};
	delete $self->{Columns}->{$name};
	return $self;
}

sub addColumn {
	my ($self, $name, $data) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Column '$name' already exists")
		if exists $self->{Columns}->{$name};
	
	$data->{Value} = 0 unless exists $data->{Value};
	$data->{Updated} = 0 unless exists $data->{Updated};
	
	$self->{Columns}->{$name} = shared_clone($data);

	return $self;
	
}

sub isFailed {
	my $self = shift;
	return $self->get('Status')==$self->STATUS_FAILED;
}

# marks the object as 'New'
sub markNew {
	my $self = shift;
	return $self->set('Status', $self->STATUS_NEW);
}

# marks the object as 'Done'
sub markDone {
	my $self = shift;
	return $self->set('Status', $self->STATUS_DONE);
}

# marks the object as 'Failed'
sub markFailed {
	my $self = shift;
	return $self->set('Status', $self->STATUS_FAILED);
}

sub getFailedCount {
	my ($self, $dbh) = @_;
	my $obj = $self->new;
	$obj->set('Status', $obj->STATUS_FAILED);
	return $obj->selectCount($dbh);
}

# this functions inserts appropriate table into database.
# furthermore, child objects could use the function for creating required folders, etc.
# don't forget to call the base function from child objects
sub prepareEnvironment {
	my ($self, $dbh) = @_;
	my $sql = $self->buildTableSql();
	ISoft::DB::do_query($dbh, sql=>$sql);
}

# for unexpected operations
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	# to be implemented in children
}

# returns an instance of HTTP::Request for fetching necessary data
sub getRequest {
	my $self = shift;
	return HTTP::Request->new('GET', $self->get('URL'));
}

# performs processing of requested content
sub processContent {
	my ($self, $dbh, $content) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"The function is not implemented yet");
	
}

# decodes content and returns an instance of HTML::TreeBuilder::XPath, but you can override the function in children
sub prepareContent {
	my ($self, $response) = @_;
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($response->decoded_content());
	return $tree;
}

# in case of html tree calls the delete method
sub releaseContent{
	my ($self, $content) = @_;
	if (my $rf = ref $content){
		
		if($rf eq 'HTML::TreeBuilder::XPath'){
			$content->delete();
		}
		
		
	}
}

# processes an instance of HTTP::Response for the previously obtained request
sub processResponse {
	my ($self, $dbh, $response, $debug) = @_;
	
	# store the response
	#$self->{response} = shared_clone($response);
	
	# set debug mode
	$self->debug($debug);
	
	# mark this member as 'Done'. note that this flag might be altered during processing the object (especially for Category)
	$self->markDone();

	my $content = $self->prepareContent($response);
	$self->processContent($dbh, $content);
	
	# common operation for processing all unexpected objects
	$self->processUnexpected($dbh, $content);
	
	# release tree
	$self->releaseContent($content);
	
	# update the associated database record
	$self->update($dbh) unless $debug;
	
	# we will not commit changes here, it should be done by caller
	
	return $self;
}

# 0..15
sub getExceptionWeight {
	my($self, $exception) = @_;
	if(my $name = ref $exception){
		if($name eq 'ISoft::Exception::NetworkError'){
			return 3;
		} elsif($name eq 'ISoft::Exception::NetworkError::ProxyError'){
			return 0;
		} elsif($name eq 'ISoft::Exception::ScriptError'){
			return -1;
		} elsif($name eq 'ISoft::Exception::DB::ValidationError'){
			return 5;
		} elsif($name eq 'ISoft::Exception::DB'){
			return 5;
		} else {
			# unknown error
			return -1;
		}
	} else {
		# perl exception;
		return -1; # stop right now!
	}
	
}


1;
