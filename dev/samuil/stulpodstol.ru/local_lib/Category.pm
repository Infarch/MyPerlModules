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

	my $page = '';	
	my @pagers = $tree->findnodes( q{//div[@class='pages']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./span/following-sibling::a[1]/@href} );
		$page = $page ? $self->absoluteUrl($page) : '';
	}
	return $page;	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	#throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	return undef;
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='catalog-item-fix']} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./div[@class='catalog-title']/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./div[@class='catalog-title']/a/@href} ) );
		$h{Picture} = $self->absoluteUrl( $node->findvalue( q{./div[@class='cabinet-item-image-outer']/a/img/@src} ) );
		push @list, \%h;
		
	}
		
	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='cabinet-item']} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./div[@class='cabinet-item-title']/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./div[@class='cabinet-item-title']/a/@href} ) );
		push @list, \%h;
		
	}
	
	return \@list;
}



1;
