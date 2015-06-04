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
	
	my @pagers = $tree->findnodes( q{.//div[@class="r"]} );
	if(@pagers > 0){
		my @arrows = $pagers[1]->findnodes( q{./a} );
		foreach my $arrow (@arrows){
			my $txt = $arrow->as_HTML('<>&', '', {});
			if($txt=~/Next/){
				if($txt=~/href="([^"]+)"/) #"
				{
					my $x = $self->absoluteUrl($1);
					$x=~s/&amp;/&/g;
					return $x;
				}
			}
		}
	}
	return '';
}

# extracts the category description
sub extractDescription {
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	return [];
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	my @nodes = $tree->findnodes( q{//div[@class="catItem l pr gb5"]/a[@class="catImg"]} );
	my @data;
	foreach my $node (@nodes){
		my $item = {
			Name => $node->findvalue( './@title' ),
			URL => $self->absoluteUrl($node->findvalue( './@href' ))
		};
		push @data, $item;
	}
	return \@data;
}



1;
