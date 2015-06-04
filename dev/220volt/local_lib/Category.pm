package Category;

use strict;
use warnings;

use Data::Dumper;
use URI::Escape;

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
	my ($self, $tree) = @_;
	
	my $page = '';	
	my @pagers = $tree->findnodes( q{//div[@class='pager']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		
		my @elements = $pager->findnodes(q{./div[@class="fr"]/ul/li});
		if(@elements){
			my $element = pop @elements;
			
			my @links = $element->findnodes(q{./a});
			if(@links){
				$page = $self->absoluteUrl($links[0]->findvalue('./@href'));
			}
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
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//ul[@class="group_list"]/li[@class="group"]/div[@class="rounded"]/div[@class="title"]/span[@class="_jslink"]} );
	
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		
		my $tt = $node->findvalue( q{./@title} );
		$tt  = uri_unescape($tt);
		if($tt =~ /href="([^"]+)"/) #"
		{
			$h{URL} = $self->absoluteUrl( $1 );
		}else{
			die "no href in url $tt";
		}
		
		push @list, \%h;
		
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//p[@class="model"]/a[1]} );
	unless(@nodes){
		@nodes = $tree->findnodes( q{//div[@class="item-name"]/a[1]} );
	}
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
