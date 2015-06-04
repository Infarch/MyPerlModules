package Product;

use strict;
use warnings;

use Property;
use ProductDescriptionPicture;
use ProductPicture;



use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);


sub trim ($) {
	my $x = shift;
	if($x){
		$x =~ s/^\s+//;
		$x =~ s/\s+$//;
	}
	return $x;
}


# returns an instance of a class representing ProductDescriptionPicture.
# uncomment and override the function for using another class.
sub newProductDescriptionPicture {
	my $self = shift;
	return ProductDescriptionPicture->new();
}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ProductPicture->new();
}

# for unexpected operations
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	my @groups = $tree->findnodes( q{//div[@class="har1"]} );
	
	my $order = 0;
	foreach my $group (@groups){
		
		my $group_name = $group->findvalue( q{./div[@class="har2"]} );
		my @properties = $group->findnodes( q{./table[@class="har3"]/tr} );
		
		foreach my $property (@properties){
			
			my $name = trim $property->findvalue( q{./td[@class="har3-1"]} );
			
			$_->delete() foreach $property->findnodes( q{./td[@class="har3-2"]/*} );
			
			my $value = trim $property->findvalue( q{./td[@class="har3-2"]} );
			
			if($self->debug()){
				
				#$self->debugEcho("Property:");
				#$self->debugEcho([$order, $group_name, $name, $value]);
				
			} else {
				
				my $prop = Property->new;
				$prop->set('Product_ID', $self->ID);
				$prop->set('OrderNumber', $order);
				$prop->set('Group', $group_name);
				$prop->set('Name', $name);
				$prop->set('Value', $value);
				
				$prop->insert($dbh, 1); # insert fast
			}
			
			$order++;
			
		}
		
	}
	
	
}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	my @nodes = $tree->findnodes( q{//ul[@class="hcList"]/li} );
	
	# extract links and search the main picture
	my @links;
	my $main;
	
	foreach my $node (@nodes){
		my $link = $node->findvalue( q{./a/@href} );
		my $class = $node->attr('class');
		if ($class && index($class, 'active')>=0){
			$main = $link;
		} else {
			push @links, $link;
		}
	}

	unshift @links, $main if $main;
	@links = map { $self->absoluteUrl($_) } @links;
	return \@links;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list = $tree->findnodes( q{//div[@itemprop="description"]} );
	if(my $node = shift @list){
		return [$node];
	}

	return [];
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	my $price = $tree->findnodes( q{//b[@itemprop="price"]} )->get_node(1)->as_text();
	$price =~ s/\D//g;
	$data{Price} = $price if $price;
	
	my $article = $tree->findnodes( q{//div[@class='one-item-article']} )->get_node(1)->as_text();
	$data{InternalID} = $article if $article;
	
	# check vendor
	
	my $way = $tree->findnodes( q{//div[@class="way"]} )->get_node(1);
	if($way){
		
		my @alist = $way->findnodes( q{./a} );
		foreach my $a (@alist){
			my $href = $a->attr('href');
			if($href =~ /\?brands=/){
				$data{Vendor} = $a->as_text();
				last;
			}
		}
	}
	
	
	return \%data;
}





1;
