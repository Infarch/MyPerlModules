package Product;

use strict;
use warnings;
use utf8;

use lib ("/work/perl_lib");

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
#sub newProductPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::ProductPicture->new;
#}

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
	
	my @piclist;
	
	# extract main picture
	my $url = $tree->findvalue(q{//div[@class='main_text']/table/tr/td/div/span[@class='img']/img/@src});
	
	if($url){
		push @piclist, $self->absoluteUrl($url);
	}
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	my @list = $tree->findnodes(q{//div[@class='main_text']//div[@id='category_content_1'] | //div[@class='main_text']//table[@id='bottom_colors']});;
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	if(my $price = $tree->findvalue(q{//span[@class='span_price']})){
		$price =~ s/\D//g;
		$data{Price} = $price;
	}
	
	if($description=~/<div><b>Производитель: <\/b><span>(.+?)<\/span><\/div>/){
		$data{Vendor} = $1;
	}

	return \%data;
}





1;
