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
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
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
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class="item item-first"]|//div[@class="item"]|//div[@class="item item-last"]} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{span[@class="product-name"]/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{span[@class="product-name"]/a/@href} ) );
		$h{Price} = $node->findvalue( q{.//span[@class="price"]} );
		$h{Price} =~ s/,/./;
		$h{Status} = 3;
		push @list, \%h;
		
	}

	return \@list;
}



1;
