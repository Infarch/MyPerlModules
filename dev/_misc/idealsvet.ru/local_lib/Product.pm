package Product;

use strict;
use warnings;
use utf8;

use lib ("/work/perl_lib");

use ProductPicture;

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);



# returns an instance of a class representing ProductDescriptionPicture.
# uncomment and override the function for using another class.
#sub newProductDescriptionPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new;
#}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ProductPicture->new;
}

# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	my $url = $self->absoluteUrl( $tree->findvalue( q{//div[@class="toptovar3"]/div[@class="images3"]/a[1]/@href} ) );	
	# contains url list, each is the scalar
	my @piclist = ($url);
	
	# extract main picture
	
	# extract additional pictures
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data;# = (Description => $description);
	
	# take the main node
	my $main = $tree->findnodes( q{//div[@class="infotovar"]} )->[0];
	
	# product code
	my $iid_node = $main->findnodes( q{div[1]} )->[0];
	foreach($iid_node->content_list()){
		$_->delete() if ref $_;
	}
	$data{InternalID} = $iid_node->findvalue( q{.} );	
	
	# price
	my $price = $main->findvalue( q{div[@class="pricetovar"]} );
	if($price =~ /Цена: ([0-9.]+) руб\./){
		$data{Price} = $1;#int($price);#sprintf '%.2f', $price;
	}else{
		die "Bad price '$price'";
	}
	
	# description
	my @dnodes = $main->findnodes( q{div[@class="texttovar"]|div[@class="opisanie"]} );
	my $descr = join '', map { $self->asHtml($_) } @dnodes;
	
	$data{Description} = $descr;
	
	return \%data;
}





1;
