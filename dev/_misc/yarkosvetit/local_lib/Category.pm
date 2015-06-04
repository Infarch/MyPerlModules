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
	
	my $page = '';	
	my @pagers = $tree->findnodes( q{//li[@class="pager-next"]/a[@class="active"]} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./@href} );
		$page = $page ? $self->absoluteUrl($page) : '';
	}
	return $page;	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	
	#throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	if($self->get('Level')==0){
		
		my @nodes = $tree->findnodes( q{//ul[@class="menu"]/li/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			# the 'Picture' key is reserved for the category picture
			#$h{Picture} = $self->absoluteUrl( $node->findvalue( q{} ) );
			push @list, \%h;
			
		}

	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class="product_title"]/a} );
	foreach my $node (@nodes){
		my %h;
		#$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
