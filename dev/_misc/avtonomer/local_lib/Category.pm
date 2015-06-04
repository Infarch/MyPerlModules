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
	my @pagers = $tree->findnodes( q{//span[@class='btn-next']/a} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./@href} );
		$page = $page ? $self->absoluteUrl($page) : '';
		if($page =~ /#$/){
			$page = '';
		}
	}
	return $page;	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	return undef;
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

	my @nodes = $tree->findnodes( q{//div[@class="text"]/strong/a} );
	foreach my $node (@nodes){
		
		my $name = $node->findvalue( q{.} );
		my $url = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		
		$name =~ s/\s//g;
		$url =~ s/nomer(\d+)$/foto$1/;
		
		my %h;
		$h{Name} = $name;
		$h{URL} = $url;
		push @list, \%h;
		
	}

	return \@list;
}



1;
