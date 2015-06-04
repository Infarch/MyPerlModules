package Category;

use strict;
use warnings;

use utf8;

#use HTML::TreeBuilder::XPath;

# base class
use base qw(ISoft::ParseEngine::Member::Category);

use CategoryPicture;
use Product;
use Price;


# returns an instance of a class representing Product.
# override the function for using another class.
sub newProduct {
	my $self = shift;
	return Product->new;
}



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

sub getNewProducts {
	my ($self, $dbh, $allow_prod_ids) = @_;
	my $obj = Product->new;
	$obj->set('Category_ID', $self->ID);
	$obj->set('IsNew', 1);
	$obj->set('ID', $allow_prod_ids) if defined $allow_prod_ids;
	
	#$obj->maxReturn(2); # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
	my $reff = $obj->listSelect($dbh);
	return wantarray ? @$reff : $reff;
}

sub getProducts {
	my ($self, $dbh, $allow_prod_ids) = @_;
	my $obj = Product->new;
	$obj->set('Category_ID', $self->ID);
	$obj->set('ID', $allow_prod_ids) if defined $allow_prod_ids;
	
#	$obj->where('and Description like \'%бренд:%\'');
	
	my $reff = $obj->listSelect($dbh);
	return wantarray ? @$reff : $reff;
}

sub getCategories {
	my ($self, $dbh, $allow_cat_ids) = @_;
	my $obj = $self->new;
	$obj->set('Category_ID', $self->ID);
	
	$obj->set('ID', $allow_cat_ids) if defined $allow_cat_ids;
	
	my $reff = $obj->listSelect($dbh);
	return wantarray ? @$reff : $reff;
}


# for unexpected operations (price)
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	# !!!!!!!!!!!!!
	return;
	
	
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


sub extractDescription {
	my ($self, $tree) = @_;
	
	my @list = $tree->findnodes( q{//td[@class='content-text']/p[@align='justify']} );
	
	if (@list==1){
		return $self->asHtml($list[0]);
	}
	
	return '';
}

sub extractNextPage {
	my ($self, $tree) = @_;
	
	my @pagers = $tree->findnodes( q{//div[@class='pages']} );
	return '' if @pagers==0;
	my $pager = shift @pagers;
	
	my $page = $pager->findvalue( q{./span/following-sibling::a[1]/@href} );
	return $page ? $self->absoluteUrl($page) : '';
	
#	my $val = $tree->findvalue( q{//div[@class='pages' and position()=1]/span/following-sibling::a[1]/@href} );
#	if($val){
#		return $self->absoluteUrl($val);
#	} else {
#		return '';
#	}
}

sub insertProducts {
	my ($self, $dbh, $data) = @_;
	
	foreach my $dataitem (@$data){
		
		my $obj = $self->newProduct();
		$obj->set('Category_ID', $self->ID);
		$obj->set('URL', $dataitem->{URL});
		
		unless ($obj->checkExistence($dbh)){
			$obj->setByHash($dataitem);
			$obj->set('IsNew', 1);
			$obj->insert($dbh);
		} else {
			# update the existing one by outer price block
			$obj->set('OuterPrice', $dataitem->{OuterPrice});
			$obj->update($dbh);
		}
		
	}
	
}


sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class='cabinet-item']} );
	foreach my $node (@nodes){
		my $name = $node->findvalue( q{.//div[@class='cabinet-item-title']/a} );
		my $url = $node->findvalue( q{.//div[@class='cabinet-item-title']/a/@href} );
		my $op = $node->findvalue( q{.//b[@class='styleprice']} );
		if(!$op){
			$op = $node->findvalue( q{.//b[@style='color:#E56C2A;font-size: 12px;']} );
		}
		$op =~ s/\D//g;
		$op ||= undef;
		my $text = $node->as_text();
		my $pf = $text=~/\sот[:0-9 ]/ || 0;
		
		push @list, {
			Name => $name,
			URL => $self->absoluteUrl($url),
			OuterPrice => $op,
			PriceFrom => $pf,
		};
	}
	
	return \@list;
}


sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	# !!!!!!!!!!!!!!
	return \@list;
	
	
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
