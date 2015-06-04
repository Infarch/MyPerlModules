package Album;

use strict;
use warnings;

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Album);


# returns an instance of a class representing Photo.
# override the function for using another class.
#sub newPhoto{
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::Photo->new;
#}

sub extractNextPage {
	return undef;	
}

# extracts the album description
sub extractDescription {
	return undef;
}

# extract photos
sub extractPhotos {
	my ($self, $tree) = @_;
	my @list;
	my @nodes = $tree->findnodes( q{//div[@class="pictures"]/div[@class="picture-frame"]} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./p} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./a/@href} ) );
		push @list, \%h;
	}
	return \@list;
}

1;
