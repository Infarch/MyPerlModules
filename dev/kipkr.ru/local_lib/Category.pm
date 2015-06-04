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

	my $level = $self->get('Level');
	
	my @nodes;
	@nodes = $tree->findnodes( q{//td[@class="tpl_mainarea"]/table[@class="WDTBL"]/tbody/tr[1]/td[last()]/a[1]} );

	foreach my $node (@nodes){
		my %h;
		my $name = $node->findvalue( q{.} );
		$name =~ s/^[0-9. ]+//;
		$h{Name} = $name;
		
		my $url = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		next if $url =~ /htm(l|)$/i;
		$h{URL} = $url;
		
		push @list, \%h;
	}
	
	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//td[@class="tpl_mainarea"]/table[@class="WDTBL"]/tbody/tr[1]/td[last()]/a[1]} );
	
	foreach my $node (@nodes){
		my %h;
		my $url = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		next if $url !~ /htm(l|)$/i;
		$h{URL} = $url;
		
		$h{Name} = $node->findvalue( q{.} );
		
		push @list, \%h;
		
	}

	return \@list;
}



1;
