package ISoft::ParseEngine::Login::phpBB;

# performs login into phpBB forums

use strict;
use warnings;

use base qw(ISoft::ParseEngine::Login);


sub checkLogin {
	my ($self, $response) = @_;
	my $content = $response->decoded_content();
	return $content =~ /<a href=".*?\?mode=logout.*?">/;
}

sub applyCredentials {
	my ($self, $formdata) = @_;
	
	$formdata->{fields}->{username} = $self->username();
	$formdata->{fields}->{password} = $self->password();
	
}

sub extractForm {
	my ($self, $content) = @_;
	
	my $formclause = q{//form};
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);
	
	my @forms = $tree->findnodes($formclause);
	
	return shift @forms;
	
}


1;
