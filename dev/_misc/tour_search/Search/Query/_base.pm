package Search::Query::_base;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use URI;

# deprecated
our $field_config = {};





# constructor
sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  my %params  = (
  	
  	config => undef,
  	browser => undef,
  	virtual_form => {},
  	content => undef,
  	next_page => undef, # this should be initialized by a child class using url of the next page during execution of 'parsePage'
  	
  	# allow to locate the search form. one of the three parameters should be defined
#  	form_name => undef,
#  	form_id => undef,
#  	form_number => undef,
  	
  	
	  @_ # init
  );
  return bless(\%params, $class);
}


# this method should be called just after that the object has been created via 'new'.
# performs query according to the specified config and stores fetched content for further parsing
# takes a reference to hash containing query params.
# returns 1 if success, 0 otherwise
sub prepare {
	my($self, $query) = @_;
	
	my $browser = LWP::UserAgent->new;
	
	$self->{browser} = $browser;
	
	$browser->timeout(20);
	$browser->cookie_jar({});
	

	$self->requestSearchForm();
	
	while( my($key, $val) = each %$query ){
		$self->doSetFormField($key, $val);
	}

	my $response = $self->doQuery();
	$self->{content} = $response->decoded_content();

	my $stop = 0;
	my @list;
	do {
		push @list, $self->parsePage();
		if ($query->{limit} && $query->{limit} > @list){
			if($self->{next_page}){
				$response = $browser->get($self->{next_page});
				unless($response->is_success()){
					print "Cannot get the next page\n";
					$stop = 1;
				}
			} else {
				$stop = 1;
			}
		} else {
			$stop = 1;
		}
		
	}(!$stop);
	
	
	
#	my $form = $self->findSearchForm($response);
#	while( my($key, $val) = each %$query ){
#		$form = $self->setFormField($form, $key, $val);
#	}

}

# the function returns array of hash references.
# each the hash contains information about a data item
sub parsePage {
	my ($self) = @_;
	
	my @list;
	
	my $items = $self->getDataItems();
	foreach my $item (@$items){
		my $di = $self->parseDataItem($item);
		push( @list, $di ) if defined $di;
	}
	
	return @list;
}

sub parseDataItem {
	die "Abstract function was called";
}

sub getDataItems {
	die "Abstract function was called";
}

# return UNDEF if you don't want to set the field.
# is is also possible to correct the value before set.
sub beforeSetFormField {
	my ($self, $key, $value) = @_;
	return $value;
}

sub afterSetFormField {
	my ($self, $key, $value) = @_;
}

sub beforeQuery {
	my ($self) = @_;
}

# -------------- auxiliary functions --------------

sub doQuery {
	my ($self) = @_;
	
	$self->beforeQuery();
	
	my $response;
	
	my $url = $self->{config}->{submit_url};
	my $form = $self->{virtual_form};
	
	if ( uc($self->{config}->{method}) eq 'POST' ){
		# perform POST
		debug('performing post');

		$response = $self->{browser}->post($url, $form);
		
	} else {
		# perform GET
		debug('performing get');
		
		my $uri = URI->new($url);
		print $uri->query_form ( %$form ), "\n";
		$response = $self->{browser}->get($uri);
	}
	
	unless ( $response->is_success() ){
		die 'Request failed: '.$response->status_line();
	}
	
	return $response;
}

sub doSetFormField {
	my ($self, $key, $value) = @_;

	unless (exists $self->{config}->{mapping}->{$key}){
		die "The field $key has no mapping";
	}
	
	return unless defined ($value = $self->beforeSetFormField($key, $value));
	
	$self->directSetFormField($key, $value);
	
	$self->afterSetFormField($key, $value);
	
}

sub directSetFormField {
	my ($self, $key, $value) = @_;
	
	if( exists $self->{config}->{variants}->{$key} ){
		if( exists $self->{config}->{variants}->{$key}->{$value}){
			$value = $self->{config}->{variants}->{$key}->{$value};
		}
	}
	
	my $name = $self->{config}->{mapping}->{$key};
	
	return unless $name;
	
	$self->{virtual_form}->{$name} = $value;
	
}

sub requestSearchForm {
	my ($self) = @_;
	
	my $resp = $self->{browser}->get($self->{config}->{search_url});
	die "Network error" unless $resp->is_success();
	
	return $resp;
}

sub x_setFormField {
	my ($self, $form, $key, $val) = @_;
	
	die "No config for the $key field" unless defined $self->{field_config}->{$key};
	my $fc = $field_config->{$key};
	
	my $name = $fc->{mapTo};
	
	# look for the input

	my @inputs = $form->findnodes( "//node()[\@name='$name']" );
	my $input = $inputs[0] or die "No input $name";
	
	# check input type
	my $tag = lc $input->tag();
	if($tag eq 'input'){
		my $type = lc $input->attr('type');
		if($type eq 'radio'){
			
			# it seems that both radio and checkbox inputs cannot be processed by this way. they have no text representation
			# and might be placed anywhere
			
		} elsif ($type eq 'checkbox') {
			
			
			
		} elsif ($type eq 'hidden' || $type eq 'password' ||$type eq 'text') {
			$input->attr('value', $val);
		}
	} elsif ($tag eq 'select') {
		# get options
		foreach my $option ($input->findnodes('./option')){
			if($option->as_text() eq $val){
				$option->attr('selected', 1);
			} else {
				$option->attr('selected', undef);
			}
		}
		
	} elsif ($tag eq 'textarea'){
		
		die "Textarea is not implemented jet";
		
	} else {
		die "Bad input tag $tag";
	}
	
	return $form;
}

sub x_findSearchForm {
	my ($self, $response) = @_;
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content( $response->decoded_content() );
	
	my $clause;
	
	if ($self->{form_name}){
		$clause = "//form[\@name='$self->{form_name}']";
	} elsif ($self->{form_id}){
		$clause = "//form[\@id='$self->{form_id}']";
	} elsif (defined $self->{form_number}){
		$clause = "//form";
	} else {
		die "Cannot determine how to search form";
	}
	
	my @forms = $tree->findnodes($clause);
	my $form;
	
	if(defined $self->{form_number}){
		die "Cannot find form" if @forms == 0;
		$form = $forms[$self->{form_number}];
	} else {
		die "Cannot find form" if @forms != 1;
		$form = $forms[0];
	}
	
	$form->detach();
	$tree->delete();
	return $form;
}

sub x_query {
	my ($self, $browser, $query) = @_;
	
	my $response;
	
	if ( uc($self->{method}) eq 'POST' ){
		# perform POST
		debug('performing post');

		$response = $browser->post($self->{url}, $query);
		
	} else {
		# perform GET
		debug('performing get');
		
		my $url = URI->new($self->{url});
		print $url->query_form ( %$query ), "\n";
		$response = $browser->get($url);
	}
	
	unless ( $response->is_success() ){
		die 'Request failed: '.$response->status_line();
	}
	
	return $response;
}


sub debug {
	print "Debug: $_[0]\n";
}



1;
