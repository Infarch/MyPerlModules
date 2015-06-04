package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new(@_);

	# create additional columns
	
#  $self->addColumn('OrderNumber', {
#		Type => $ISoft::DB::TYPE_INT,
#  });

  return $self;
}


# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
#sub newCategoryPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::CategoryPicture->new;
#}

# change class name for using another class.
# or just remove the function if the standard class is ok for you.
sub newProduct {
	return Product->new;
}


# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}


sub extractNextPage {
	my ($self, $tree) = @_;
	
	my $pn = '/page' . ($self->get('Page') + 1);
	
	my $page = '';	
	my @pagers = $tree->findnodes( q{//div[@class='page-navigation fl']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		my @a = $pager->findnodes( q{.//a} );
		foreach (@a){
			my $href = $_->findvalue( './@href' );
			if( index($href, $pn) > 0 ){
				$page = $self->absoluteUrl($href);
				last;
			}
		}
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
	return [];
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//ul[@id="catalog-items"]/li/div/div[2]/a} );
	foreach my $node (@nodes){
		my %h;
		my $name = $node->findvalue( q{.} );
		$name=~s/^\s+//;
		$h{Name} = $name;
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
