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
	my $pn = $self->get('Page');
	my $tagpattern;
	my $attrpattern;
	if($pn==1){
		$tagpattern = './/a';
		$attrpattern = './@href';
	} else {
		$tagpattern = './/span';
		$attrpattern = './@data-href';
	}
	$pn = 'page=' . ($pn + 1);
	my $page = '';	
	my @pagers = $tree->findnodes( q{//div[@class='pages_box']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		
		my @a = $pager->findnodes( $tagpattern );
		foreach (@a){
			my $href = $_->findvalue( $attrpattern );
			if( $href =~ /$pn$/ ){
				$page = $self->absoluteUrl($href);
				last;
			}		
		}
	}
	return $page;	
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
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//td[@class="tcat2"]} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./h2/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./h2/a/@href} ) );
		$h{ShortDescription} = $node->findvalue( q{./p} );
		push @list, \%h;
	}

	return \@list;
}



1;
