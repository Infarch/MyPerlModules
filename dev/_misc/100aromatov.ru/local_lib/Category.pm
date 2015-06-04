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

sub extractNextPage {
	my ($self, $tree) = @_;
	my $page = '';	
	my @pagers = $tree->findnodes( q{//table[@bgcolor='#eeeeee']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./tr/td/b[2]/following-sibling::a[1]/@href} );
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
	
	my @list;
	
	if($self->get('Level')==0){
		
		my @nodes = $tree->findnodes( q{//h1[1]/following-sibling::table[1]//a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			my $href = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			if($href=~/fid=(\d+)/){
				$h{Picture} = "http://www.100aromatov.ru/showpic.asp?type=1\&id=$1";
			}
			$h{URL} = $href;
			push @list, \%h;
		}
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//a[@class='aromatname']} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
