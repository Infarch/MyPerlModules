package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);
use Product;



# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
#sub newCategoryPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::CategoryPicture->new;
#}

# change class name for using another class.
# or just remove the function if the standard class is ok for you.
sub newProduct {
	my $self = shift;
	return Product->new;
}


# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}


sub extractNextPage {
	return '';
}

# extracts the category description
sub extractDescription {
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	
	return [];
	
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//a[@class="greyLink"]} );
	foreach my $node (@nodes){
		my %h;
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		$h{Name} = $node->findvalue( q{./span[1]} );
		$h{InternalID} = $node->findvalue( q{./span[3]} );
		push @list, \%h;
		
	}

	return \@list;
}



1;
