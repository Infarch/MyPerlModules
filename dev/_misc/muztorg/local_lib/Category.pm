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
	my @pagers = $tree->findnodes( q{//div[@class='right']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./span/following-sibling::a[1]/@href} );
		if($page=~/\/all\/$/){
			$page = '';
		}
		$page = $page ? $self->absoluteUrl($page) : '';
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
	
	my @list;
	
	if($self->get("Level")==0){
		my @nodes = $tree->findnodes( q{//*[@id='mainmenu']/div[2]/table/tr/td/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			push @list, \%h;
		}
	} else {
		
		my @nodes = $tree->findnodes( q{//ul[@class='redmarker small zoom1']} );
		if(@nodes > 1){
			my @subnodes = $nodes[0]->findnodes( q{.//a} );
			foreach my $node (@subnodes){
				my %h;
				$h{Name} = $node->findvalue( q{.} );
				$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
				push @list, \%h;
			}
		}
		
	}
	

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='tovar']/div[3]/span[@class='h']/a} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
