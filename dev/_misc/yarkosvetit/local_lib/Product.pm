package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;
use Property;

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

	# contains url list, each is the scalar
	my @piclist;

	my $node = $tree->findnodes( q{//div[@class="product_image"]/a} )->get_node(1);

	push @piclist, $self->absoluteUrl( $node->findvalue('./@href') );

	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;

	my @nodes = $tree->findnodes( q{//div[@class="product_inner_description"]/*} );

	return \@nodes;
}

# override
sub processProductData {
	my ($self, $dbh, $tree, $description) = @_;
	
	my $data = $self->extractProductData($tree, $description);
	my $props = delete $data->{_properties};
	$self->setByHash($data);
	if($self->debug()){
		$self->debugEcho("Product data:");
		$self->debugEcho($data);
	}
	if(defined $props){
		if($self->debug()){
			$self->debugEcho("Product properties:");
			$self->debugEcho($props);
		} else {
			foreach my $nm (keys %$props){
				my $prop = Property->new;
				$prop->set('Product_ID', $self->ID);
				$prop->set('Name', $nm);
				$prop->set('Value', $props->{$nm});
				$prop->insert($dbh, 1);
			}
		}
	}
}


sub extractProductData {
	my ($self, $tree, $description) = @_;

	my %data = (Description => $description);

	my $container = $tree->findnodes( q{//div[@class="product_inner_right"]} )->get_node(1);

	$data{Name} = $container->findvalue( q{./div[@class="product_inner_title"]} );
	$data{InternalID} = $container->findvalue( q{./div[@class="product_inner_model"]} );
	$data{Price} = $container->findvalue( q{.//span[@class="product_price"]} );
	$data{Price} =~ s/\D//g;
	
	my @dataitems = $container->findnodes( q{./div[@class="product_inner_data"]} );
	my %props;
	foreach my $dataitem (@dataitems){
		my $name = $dataitem->findvalue( q{./span[@class="data_type"]} );
		my $value = $dataitem->findvalue( q{./span[@class="data_value"]} );
		if($name && $value){
			$props{$name} = $value;
		}
	}
	$data{_properties} = \%props;
	
	return \%data;
}





1;
