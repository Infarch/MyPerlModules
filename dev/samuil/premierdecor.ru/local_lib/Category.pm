package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);




# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
#sub newCategoryPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::CategoryPicture->new;
#}

# returns an instance of a class representing Product.
# uncomment and override the function for using another class.
#sub newProduct {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::Product->new;
#}


# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}


sub extractNextPage {
	my ($self, $tree) = @_;
	
	my $page = $tree->findvalue( q{//table[@width='464']/tr/td[@class='rightlink']/a/@href} );
	$page = $page ? $self->absoluteUrl($page) : '';

	return $page;	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	return [];
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;

	# remove the 'leader'
	my @leader = $tree->findnodes( q{//td[@class='leader']} );
	foreach (@leader){
		$_->delete();
	}
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//td[@class='cat_anno']/a} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
