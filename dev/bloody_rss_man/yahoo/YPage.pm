package YPage;

use strict;
use warnings;


use HTML::TreeBuilder::XPath;
use HTTP::Request;
use LWP::UserAgent;
use URI;
use URI::Escape;


our $base_url = 'http://siteexplorer.search.yahoo.com/';

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
  	allow_requests => 3,
	  form => {},
	  agent => undef,
	  @_ # init
  );
  
  return bless(\%self, $class);
}

# main functions

sub init {
	my ($self, %params) = @_;
	
	my $agent = LWP::UserAgent->new(cookie_jar=>{});
	$agent->agent('Mozilla/5.0 (Windows; U; Windows NT 5.2; ru; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13 ( .NET CLR 3.5.30729; .NET4.0E)');
	$self->agent($agent);
	
	my $resp = $self->_startpage();

	$self->_extractForm($resp);
	
}

sub process {
	my ($self, $checkurl) = @_;
	my $form = $self->form();
	my $main_input = $form->{main_input} or die "No main input";
	$form->{fields}->{$main_input} = $checkurl;
	
	# apply inlinks
	$form->{fields}->{bwm} = 'i';
	
	# Except from this domain...
	$form->{fields}->{bwmo} = 'd';
	
	# substitite a part of form action url in order to get TSV file
	$form->{action} =~ s#/search;#/export;#;
	
	my $resp = $self->submit();
	return $self->extractData($resp);
}

sub extractData {
	my ($self, $response) = @_;
	my $content = $response->decoded_content();
	
	# split by lines
	my @lines = split "\n", $content;
	
	# just skip the first two lines
	shift @lines;
	shift @lines;
	
	my @collector;
	foreach my $line (@lines){
		my ($title, $url, $size, $format) = split "\t", $line;
		push @collector, $url;
	}
	return @collector;
}

# properties

sub form { return $_[0]->_getset('form', $_[1]); }
sub agent { return $_[0]->_getset('agent', $_[1]); }
sub allowRequests { return $_[0]->_getset('agent', $_[1]); }

# auxiliary functions

sub safeRequest {
	my ($self, $request) = @_;
	
	my $agent = $self->agent();
	
	my $allow_requests = $self->allowRequests();
	my $count = 1;
	
	my $response;
	my $pause = 0;
	do {
		if($allow_requests && $pause==$allow_requests){
			die "Request failed: ".$response->status_line();
		}
		sleep $pause if $pause++;
		$response = $agent->request( $request );
	} while ( !$response->is_success() );
	
	return $response;
}

sub submit {
	my ($self) = @_;
	
	my $form = $self->form();
	
	my $req;
	if($form->{method} eq 'GET'){
		# make URI
		my $url = $form->{action};
		$url .= '?';
		my @parts;
		while(my($key, $value)= each %{$form->{fields}}){
			$value = uri_escape($value);
			push @parts, "$key=$value";
		}
		$url .= join '&', @parts;
		$req = HTTP::Request->new(GET => $url);
	} else {
		die "POST is not implemented";
	}
	
	return $self->safeRequest($req);
}

sub _extractForm {
	my ($self, $response) = @_;
	my $tree = HTML::TreeBuilder::XPath->new;
	
	$tree->parse_content($response->decoded_content());
	
	my @forms = $tree->findnodes( q{//form} );
	my $form = shift @forms;
	unless($form){
		die "No form";
	}
	
	my %form;
	
	my $action = $form->attr('action');
	
	$form{action} = $action;
	
	my $method = $form->attr('method') || 'get';
	$form{method} = uc $method;
	
	my %fl;
	my @fields = $form->findnodes( q{.//input[@type='text'] | .//input[@type='hidden']} );
	foreach my $field (@fields){
		my $name = $field->attr('name');
		my $value = $field->attr('value');
		if($field->attr('type') eq 'text'){
			$form{main_input} = $name;
		}
		$fl{$name} = $value;
	}
	$form{fields} = \%fl;
	
	$self->form(\%form);
	
	$tree->delete();
}

sub absoluteUrl {
	my ($self, $url) = @_;
	return URI->new($url)->abs($base_url)->as_string;
}

sub _startpage {
	my $self = shift;
	my $agent = $self->agent();
	my $request = HTTP::Request->new(GET => $base_url);
	return $self->safeRequest($request);
}

sub _getset {
	my ($self, $field, $new_val) = @_;
	unless (exists $self->{$field}){
		die "No field $field";
	}
	my $old_val = $self->{$field};
	$self->{$field} = $new_val if defined $new_val;
	return $old_val;
}


1;
