package CategoryCorr;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::Category);

use CategoryPicture;
use Product;
use Price;




sub getPicture {
	my ($self, $dbh) = @_;
	
	my $pic = CategoryPicture->new;
	$pic->set('Category_ID', $self->ID);
	if($pic->checkExistence($dbh)){
		return $pic;
	} else {
		return undef;
	}
	
}

# returns an instance of HTTP::Request for fetching necessary data
sub getRequest {
	my $self = shift;
	my $url = $self->get('URL');
	$url =~ s/\?page=\d+$//;
	return HTTP::Request->new('GET', $url);
}

sub getProducts {
	my $reff = [];
	return wantarray ? @$reff : $reff;
}


sub extractDescription {
	my ($self, $tree) = @_;
	
	return '';
}

sub insertCategoryPicture {
	my ($self, $dbh, $parent, $pic) = @_;
	
	my $pic_obj = CategoryPicture->new;
	$pic_obj->set('Category_ID', $parent->ID);
	$pic_obj->set('URL', $pic);
	$pic_obj->insert($dbh);
	
}

sub extractNextPage {
	my ($self, $tree) = @_;
	
	return '';
}

sub insertProducts {
	my ($self, $dbh, $data) = @_;
	
}

sub extractProducts {
	my ($self, $tree) = @_;
	return [];
}


sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	
	my $nodes_clause = q{//td[@class='divorce-catalog-td'] | //div[@class='catalog-item-fix']};
	
	my $pic_clause = 
		q{./a[@class='catalog-divorce-image']/img/@src | ./div/a[@class='cabinet-item-image']/img/@src};
	
	my @nodes = $tree->findnodes( $nodes_clause );
	foreach my $node (@nodes){
		
		my $name = $node->findvalue( q{./div[@class='catalog-title']/a} );
		my $url = $node->findvalue( q{./div[@class='catalog-title']/a/@href} );
		my $pic_url = $node->findvalue( $pic_clause );
		
		push @list, {
			Name => $name,
			URL => $self->absoluteUrl($url),
			Picture => $self->absoluteUrl($pic_url)
		};
	}
	
	return \@list;
}



1;
