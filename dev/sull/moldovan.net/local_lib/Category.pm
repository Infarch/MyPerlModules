package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);


# returns an instance of a class representing Product.
# uncomment and override the function for using another class.
sub newProduct {
	my $self = shift;
	my $pr = new Product();
	$pr->markDone();
	return $pr;
}

sub processContent {
	my ($self, $dbh, $tree) = @_;
	
	# all products are in fake category only
	my $name = $self->get('Name');
	if($name eq 'xxx'){
		$self->processProducts($dbh, $tree);
	} else {
		$self->processSubCategories($dbh, $tree);
	}
	
}


# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;

	my @list;
	
	if($self->get('Level')==0){

		my @nodes = $tree->findnodes( q{//div[@class='CatalogColumn']/p/strong/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			push @list, \%h;
			
		}
		
	} else {
		
		my @nodes = $tree->findnodes( q{//td[@class='CatalogInside']/p/strong/a} );
		foreach my $node (@nodes){
			my %h;
			$h{Name} = $node->findvalue( q{.} );
			$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
			push @list, \%h;
		}
		
		# look for ID, create a fake directory for ajax request
		my $cnt = $self->asHtml($tree);
		if($cnt =~ / oVars.catid = '(\d+)';/){
			push @list, {
				Name => 'xxx',
				URL => "http://www.ournet.md/_php/websites.php?catid=$1\&lang=ru\&mh=1000000"
			};
			
		}
		
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//ol/li} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./p/a} );
		my $content = $self->asHtml($node);
		$content =~ /URL:\s+(.*?)</;
		$h{URL} = $1;
		push @list, \%h;
	}

	return \@list;
}



1;
