package ISoft::ParseEngine::Member::Album;

# This package represents a simple Photo album, such as Picassa album or similar

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use HTTP::Request;

use ISoft::Exception::ScriptError;

use ISoft::ParseEngine::Member::File::Photo;

# base class
use base qw(ISoft::ParseEngine::Member);



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename    => 'Album',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Page', {
		Type => $ISoft::DB::TYPE_SMALLINT,
		NotNull => 1,
		Default => 1,
  });

  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  $self->addColumn('Description', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  $self->addColumn('CreateDate', {
		Type => $ISoft::DB::TYPE_DATE,
  });

  return $self;
}

# returns an instance of a class representing Photo.
# override the function for using another class.
sub newPhoto{
	my $self = shift;
	return ISoft::ParseEngine::Member::File::Photo->new;
}

sub extractNextPage {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return '';	
}

# extracts the album description
sub extractDescription {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return '';
}

# extract photos
sub extractPhotos {
	my ($self, $tree) = @_;
	
	my @list;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \@list;
}

sub processDescription {
	my ($self, $dbh, $tree) = @_;
	my $description = $self->extractDescription($tree);
	if ($description){
		if ($self->debug()){
			$self->debugEcho('Description: '.$description);
		} else {
			$self->set('Description', $description);
		}
	}
}


sub insertPhotos {
	my ($self, $dbh, $data) = @_;
	
	foreach my $dataitem (@$data){
		my $obj = $self->newPhoto();
		$obj->set('Album_ID', $self->ID);
		$obj->setByHash($dataitem);
		$obj->insert($dbh);
	}
	
}

sub processPhotos {
	my ($self, $dbh, $tree) = @_;
	
	my $data = $self->extractPhotos($tree);
	if($self->debug()){
		$self->debugEcho("Photos:");
		$self->debugEcho($data);
	} else {
		$self->insertPhotos($dbh, $data);
	}
	
	return scalar @$data;
}

sub processContent {
	my ($self, $dbh, $tree) = @_;
	
	my $page = $self->get('Page');

	$self->processDescription($dbh, $tree) unless $self->get('Description');

	# look for photos
	my $p_count = $self->processPhotos($dbh, $tree);

	# look for the next page, but only if there are photos
	if(($p_count > 0) && (my $nextpage = $self->extractNextPage($tree))){
		if($self->debug()){
			$self->debugEcho("Next page: $nextpage");
		}
		$self->set('URL', $nextpage);
		$self->set('Page', $page+1);
		$self->markNew();
	}
	
}

sub getPhotos {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = $self->newPhoto();
	$obj->set('Album_ID', $self->ID);
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}

1;
