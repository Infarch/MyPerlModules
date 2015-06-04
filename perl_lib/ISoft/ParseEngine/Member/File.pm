package ISoft::ParseEngine::Member::File;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use File::Path;


use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'File',
	  storage => 'files',
	  
	  # don't cache files by default
	  cache => 0,
	  
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('FileName', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  return $self;
}

sub prepareEnvironment {
	my ($self, $dbh) = @_;
	if(my $storage = $self->getStorage()){
		if(!-e $storage && !-d $storage){
			mkpath($storage);
		}
	}
	return $self->SUPER::prepareEnvironment($dbh);
}

sub getStorage {
	my $self = shift;
	return $self->{storage};
}

# uses md5 algorithm to create new file name depending on the file's url.
# extension will be left unchanged.
sub getMD5Name {
	my $self = shift;
	my $name = $self->getOrgName();
	my $ext = '';
	if ($name=~/.*\.(.*)/){
		$ext = ".$1";
	}
	$name = md5_hex($self->get('URL'));
	return $name.$ext;
}

# combines the file's ID and an original extension
sub getIdName {
	my $self = shift;
	
	my $name = $self->getOrgName();
	
	my $ext = '';
	if ($name=~/.*\.(.*)/){
		$ext = ".$1";
	}

	return $self->ID . $ext;
}

# looks into the FileName field. If not defined,
# tries to extract the original name of the file from the URL
sub getOrgName {
	my $self = shift;
	my $filename = $self->get("FileName");
	return $filename if defined $filename;
	my $url = $self->get('URL');
	my $name = '';
	if($url=~/\/([^\/]+)$/){
		$name = $1;
	}
	return $name;
}

sub getNameToStore {
	my $self = shift;
	return $self->ID;
}

sub getStoragePath {
	my $self = shift;
	my $path = $self->getStorage() || '';
	$path .= '/' if $path;
	$path .= $self->getNameToStore();
	return $path;
}

sub save {
	my ($self, $content) = @_;
	my $path = $self->getStoragePath();
	if($self->debug()){
		$self->debugEcho("I'm going to save $path");
	} else {
		open XX, ">$path" or throw ISoft::Exception::ScriptError(message=>"Cannot save file $path: $!");
		binmode XX;
		print XX $content;
		close XX;
	}
	return $path;
}

sub prepareContent {
	my ($self, $response) = @_;
	return $response->content;
}

sub processContent {
	my ($self, $dbh, $content) = @_;
	
	$self->save($content);
	
}



1;
