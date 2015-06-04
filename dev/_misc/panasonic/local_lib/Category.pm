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
	
	my @pagers = $tree->findnodes( q{//div[@class='articlesc']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		#print $self->asHtml($pager);
		$page = $pager->findvalue( q{.//b/following-sibling::a[1]/@href} );
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
	
	my @blocks = $tree->findnodes( q{//div[@class="txt32c"]} );
	
	my @list;
	
	if(@blocks==2){
		my $block = shift @blocks;
		my @nodes = $block->findnodes( q{./div/ul/li/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			# the 'Picture' key is reserved for the category picture
			#$h{Picture} = $self->absoluteUrl( $node->findvalue( q{} ) );
			push @list, \%h;
			
		}
		
	} elsif(@blocks==1){
		# products
	} else {
		# error?
		die "block count error"
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @blocks = $tree->findnodes( q{//div[@class="txt32c"]} );
	my $block = shift @blocks;
	
	my @list;
	
	my @nodes = $block->findnodes( q{./div/ul/li/a} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
