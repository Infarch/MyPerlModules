package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");

use ProductPicture;

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);



# returns an instance of a class representing ProductDescriptionPicture.
# uncomment and override the function for using another class.
#sub newProductDescriptionPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new;
#}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ProductPicture->new;
}

# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	# contains url list, each is the scalar
	my @piclist = map { $self->absoluteUrl($_) } $tree->findvalues( q{.//*[@id='maincol']/div/ul/li/ul/li[3]/a/@href} );
	
	# extract main picture
	
	# extract additional pictures
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	# no description
	my @list;
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	# no more data
	
	return \%data;
}





1;
