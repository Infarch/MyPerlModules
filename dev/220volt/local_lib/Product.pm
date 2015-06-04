package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");
use utf8;
use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

use Attribute;



# for unexpected operations
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	my @props = $tree->findnodes(q{//div[@class="properties top"]/table/tr | //div[@class="properties hide"]/table/tr});
	foreach my $prop(@props){
		my @cells = $prop->findnodes(q{./td});
		my $name = $cells[0]->findvalue('.');
		my $value = $cells[1]->findvalue('.');
		
		if($self->debug()){
			$self->debugEcho("$name = $value");
		}else{
			my $attr = Attribute->new;
			$attr->set("Product_ID", $self->ID);
			$attr->set("Name", $name);
			$attr->set("Value", $value);
			$attr->insert($dbh);
		}
		
	}
}

sub extractProductPictures {
	my ($self, $tree) = @_;
	return [];
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @dlist = $tree->findnodes(q{//div[@id="descr"]});
	if(@dlist){
		@list = $dlist[0]->findnodes(q{./div[@id="detail"]});
		unless(@list){
			@list = $dlist[0]->findnodes(q{./div[@id="short"]});
		}
	}
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	my @codes = $tree->findnodes(q{//span[@class="code"]/span});
	if(@codes){
		$data{InternalID} = $codes[0]->findvalue('.');
	}
	
	my @prices = $tree->findnodes(q{//span[@itemprop="price"] | //div[@class="price alone"]});
	if(@prices){
		my $price = $prices[0]->findvalue('.');
		$price =~ s/ //g;
		$price =~ s/руб//g;
		$data{Price} = $price;
	}
	
	#throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \%data;
}





1;
