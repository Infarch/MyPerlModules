package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);

use Product;


# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
#sub newCategoryPicture {
#	my $self = shift;
#	return CategoryPicture->new;
#}

# returns an instance of a class representing Product.
# uncomment and override the function for using another class.
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
	
	return '';	
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
	
	my $level = $self->get('Level');
	if($level==0){
		
		my @nodes = $tree->findnodes( q{//div[@class='cat_lot']} );
		foreach my $node (@nodes){
			my %h;
			
			my $name = ($node->findnodes(q{.//a[@class='cat_lot_name']}))[0];
			$name = $self->asHtml($name);
			$name =~ s/<br[^>]*>/ /;
			$name =~ s/<[^>]+>//g;
			$h{Name} = $name;
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{.//a[@class='cat_lot_name']/@href} ) );
			# the 'Picture' key is reserved for the category picture
			$h{Picture} = $self->absoluteUrl( $node->findvalue( q{./a/img/@src} ) );
			push @list, \%h;
			
		}
		
		
	} elsif($level==1) {
		
		my @nodes = $tree->findnodes( q{//td[@class='menu_series_cell']/a} );
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
	
	my @nodes = $tree->findnodes( q{//div[@class='good_lot']} );
	foreach my $node (@nodes){
		my %h;
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./div[@class='category_lot_name']/div/a/@href} ) );
		$h{Price} = $node->findvalue( q{./div[@class='div_price']} );
		$h{Price} =~ s/\D//g;
		
		push @list, \%h;
		
	}

	return \@list;
}



1;
