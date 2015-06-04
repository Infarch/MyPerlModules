package Product;

use strict;
use warnings;

use utf8;

use HTML::Element;



use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

use Price;

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

# for unexpected operations (price)
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;

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
				# insert just one base price
				if($self->debug()){
					$self->debugEcho("Single price\n$pdf_url");
				} else {
					my $price_obj = Price->new;
					$price_obj->set('URL', $pdf_url);
					$price_obj->set($parent, $self->ID);
					$price_obj->insert($dbh);
				}
			}
			
		}
	}
}

# to be overriden in children
sub descriptionNodeFilter {
	my ($self, $node) = @_;
	# remove inputs
	my @bads = $node->findnodes( q{.//input} );
	foreach (@bads){
		$_->delete();
	}
	my @selects = $node->findnodes( q{.//select} );
	foreach (@selects){
		$_->attr('onchange', undef);
	}
	return 1;
}


sub extractProductPictures {
	my ($self, $tree) = @_;
	
	# extract main picture
	my @clauses = (
		q{//span[@class='img']/img/@src},
		q{//a[@id='big']/@href},
		q{//div[@class='lil_pic_div']/span/a/@href}
	);
	
	my $clause_str = join '|', @clauses;
	
	my @piclist = map { $self->absoluteUrl($_) } $tree->findvalues($clause_str);
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	my $clause_1a = q{//table[@class='behaviour']};
	my $clause_1b = q{//table[@class='cat3']/tr[3]/td[@colspan='2']};
	my $clause_1c = q{//table[@class='cat4']};
	
	# *******
	
	my $clause_2a = q{//td[@class='content']/table[@width='100%']/tr[1]/td[last()]};
	my $clause_2b = q{//table[@id='bottom_colors']};
	
	# *******
	
	my $clause_3a = q{//div[@id='category_content_1'] | //div[@id='category_content_3']};
	my $clause_3b = q{//div[@class='item_category_title'] | //div[@class='element_item']};
	
	# each the clause hav own process method, but all the extracted nodes should be wrapped into special table
	
	my $special_attr_name = 'section';
	
	my @list_1 = $tree->findnodes($clause_1a);
	if(@list_1 > 0){
		
		foreach my $item(@list_1){
			$item->attr($special_attr_name, 1);
			push @list, $item;
		}
		
		# only one
		my $el_1b = ($tree->findnodes($clause_1b))[0];
		$el_1b->detach();
		my $spec = HTML::Element->new('table', $special_attr_name=>1);
		my $xr = HTML::Element->new('tr');
		$spec->push_content($xr);
		
		$el_1b->attr('colspan', undef);
		$xr->push_content($el_1b);
		
		push @list, $spec;
		
		my @list_1c = $tree->findnodes($clause_1c);
		foreach my $item(@list_1c){
			$item->attr($special_attr_name, 2);
			push @list, $item;
		}
		
	} elsif ( (my @list3a = $tree->findnodes($clause_3a)) > 0 ) {
		
		foreach my $xx (@list3a){
			$xx->attr($special_attr_name, 1);
			push @list, $xx
		}
		
		my @sublist = $tree->findnodes($clause_3b);
		foreach my $yy (@sublist){
			$yy->attr($special_attr_name, 3);
			push @list, $yy;
		}
		
	} elsif ( defined( my $el_2 = ($tree->findnodes($clause_2a))[0] ) ) {
		
		$el_2->detach();
		my $spec = HTML::Element->new('table', $special_attr_name=>1);
		my $xr = HTML::Element->new('tr');
		$spec->push_content($xr);
		$xr->push_content($el_2);
		push @list, $spec;
		
		if(my $ctable = ($tree->findnodes($clause_2b))[0]){
			$ctable->attr($special_attr_name, 1);
			push @list, $ctable;
		}
	}	else {
		
		print "\n\nNo data!\n\n";
		
	}
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	if($description=~/<div><b>Производитель:\s<\/b><span>(.*?)<\/span><\/div>/){
		$data{Vendor} = $1;
	} elsif ($description=~/<td class="l_c">Производитель:<\/td>\s*<td class="r_c">(.*?)<\/td>/){
		$data{Vendor} = $1;
	}

	if($description=~/<span class="span_price"[^>]*>(.*?)<\/span>/){
		my $price = $1;
		$price =~ s/[^\d]//g;
		$data{Price} = $price;
	}
	
	return \%data;
}


1;
