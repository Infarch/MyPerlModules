package Category;

use strict;
use warnings;

use Product;

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

# returns an instance of a class representing Product.
# uncomment and override the function for using another class.
sub newProduct {
	my $self = shift;
	return Product->new;
}


# for unexpected operations (price)
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	return if $self->get('Page') > 1;
	my $parent = $self->tablename() . '_ID';
	
	# check whether there is price
	my @forms = $tree->findnodes( q{//form[@name='pdf_form']} );
	if(@forms==1){
		my $formnode = $forms[0];
		my $pdf_url = $formnode->findvalue( q{./@action} );
		my $lnk = $formnode->findvalue( q{.//input[@name='url']/@value} );
		if($pdf_url && $lnk){
			$pdf_url = $self->absoluteUrl($pdf_url);
			$pdf_url .= "?url=$lnk";
			
			my @colornodes = $formnode->findnodes( q{.//select[@name='color']/option} );
			if(@colornodes>0){
				# insert price for each the color
				if($self->debug()){
					$self->debugEcho("Prices");
				}
				foreach my $colornode (@colornodes){
					my $color = $colornode->findvalue( q{./@value} );
					if($self->debug()){
						$self->debugEcho($pdf_url."&color=$color");
					} else {
						my $price_obj = Price->new;
						$price_obj->set('URL', $pdf_url."&color=$color");
						$price_obj->set($parent, $self->ID);
						$price_obj->insert($dbh);
					}
				}
			} else {
				if($self->debug()){
					$self->debugEcho("Single price\n$pdf_url");
				} else {
					# insert just one base price
					my $price_obj = Price->new;
					$price_obj->set('URL', $pdf_url);
					$price_obj->set($parent, $self->ID);
					$price_obj->insert($dbh);
				}
			}
			
		}
	}
}


sub extractNextPage {
	my ($self, $tree) = @_;
	
	#throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	my $page = '';	
	my @pagers = $tree->findnodes( q{//span[@class='pages']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./a[@class='number_active']/following-sibling::a[1]/@href} );
		$page = $page ? $self->absoluteUrl($page) : '';
	}
	return $page;	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	#throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='cabinet-item-simple']} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./div[@class='cabinet-item-title']/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./div[@class='cabinet-item-title']/a/@href} ) );
		
		my $picurl = $node->findvalue( q{./div[2]/a/img/@src} );
		if($picurl){
			$h{Picture} = $self->absoluteUrl($picurl);
		}
		
		next if $h{URL} eq 'http://www.profcompletecafe.ru/catalog/flors/';
		#next if $h{URL} eq 'http://www.profcompletecafe.ru/catalog/solid-furniture/';
		#next if $h{URL} eq 'http://www.profcompletecafe.ru/catalog/cafebarsofas/sofas-for-order/';
		
		push @list, \%h;
		
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='cabinet-item']} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./div[@class='cabinet-item-title']/a} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./div[@class='cabinet-item-title']/a/@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
