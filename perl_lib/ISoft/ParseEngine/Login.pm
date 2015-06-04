package ISoft::ParseEngine::Login;

# performs login into protected sites

use threads;
use threads::shared;

use strict;
use warnings;

use base qw(ISoft::ClassExtender);


use HTML::TreeBuilder::XPath;
use URI;

use ISoft::Exception::ScriptError;


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %self  = (
	  username => '',
	  password => '',
	  login_url => '',
	  @_ # init
  );
  
  return bless(shared_clone(\%self), $class);
}

# the main function. returns 0 or 1 depending on login result
sub login {
	my ($self, $agent) = @_;
	
	my $resp = $agent->get($self->loginUrl());
	return 0 unless $resp->is_success();
	
	my $loginpage_content = $resp->decoded_content();
	
	my $form = $self->extractForm($loginpage_content);
	return 0 unless defined $form;
	
	my $formdata = $self->parseForm($form);
	
	$self->applyCredentials($formdata);
	
	$resp = $self->sendForm($agent, $formdata);
	return 0 unless $resp->is_success();
	
	return $self->checkLogin($resp);
	
}

sub checkLogin {
	my ($self, $response) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Not implemented");
	
	my $content = $response->decoded_content();
	return $content =~ /logout/;
}

sub sendForm {
	my ($self, $agent, $formdata) = @_;
	
	my $method = $formdata->{method};
	my $resp;
	if($method eq 'POST'){
		$resp = $agent->post($formdata->{url}, $formdata->{fields});	
	} elsif($method eq 'GET') {
		$resp = $agent->get($formdata->{url}, $formdata->{fields});
	} else {
		throw ISoft::Exception::ScriptError(message=>"Unknown method '$method'");
	}
	
	return $resp;
	
}

sub applyCredentials {
	my ($self, $formdata) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Not implemented");
	
	$formdata->{fields}->{username} = $self->username();
	$formdata->{fields}->{password} = $self->password();
	
}

# formdata = {
#  url => '',
#  method => '',
#  fields => {
#   ... => ...,
#   ... => ...,
#  }
# }
sub parseForm {
	my ($self, $form) = @_;
	
	my $method = uc $form->attr('method') || 'POST';
	my $url = $form->attr('action') || $self->loginUrl();
	$url = URI->new_abs( $url, $self->loginUrl() )->as_string();
	
	my @inputs = $form->findnodes( q{.//input} );
	my %fields;
	foreach my $input (@inputs){
		my $name = $input->attr('name') || next;
		if (defined (my $type = $input->attr('type'))){
			next if $type eq 'checkbox';
		}
		my $val = $input->attr('value');
		$fields{$name} = $val;
	}

	my %formdata = (
		url => $url,
		method => $method,
		fields => \%fields
	);
	
	return \%formdata;
}

sub extractForm {
	my ($self, $content) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Not implemented");
	
	my $formclause = q{}; # <-- write clause here
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	
	my @forms = $tree->findnodes($formclause);
	
	return shift @forms;
	
}

sub loginUrl { return $_[0]->_getset('login_url', $_[1]); }
sub username { return $_[0]->_getset('username', $_[1]); }
sub password { return $_[0]->_getset('password', $_[1]); }

1;
