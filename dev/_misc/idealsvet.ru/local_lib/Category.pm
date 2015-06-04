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
	my @pagers = $tree->findnodes( q{//table[@width="705"]/tr[last()]/td} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./b/following-sibling::a[1]/@href} );
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
	
	if($self->get("Level")==0){
		# root
		my @nodes = $tree->findnodes( q{/html/body/div[4]/div[2]/div[2]/div/a[1]} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			push @list, \%h;
		}
		
	}else{
		
		#my @nodes = $tree->findnodes( q{/html/body/div[4]/div[3]/table/tr/td/div[4]/div[2]/a} );
		my @nodes = $tree->findnodes( q{/html/body/div[4]/div[3]/table/tr/td/div[@class="toptovar2"]/div[2]/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			push @list, \%h;
		}
		
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class="infotovar"]} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{a/@href} ) );
		
		my @sss = $node->findnodes( q{div[@class="texttovar"]} );
		my $sd = join '<br/>', map { $_->findvalue('.') } @sss;
		$h{ShortDescription} = $sd;
		
		push @list, \%h;
		
	}

	return \@list;
}



1;
