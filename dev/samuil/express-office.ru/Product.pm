package Product;

use strict;
use warnings;

use utf8;

use Error ':try';
use HTML::TreeBuilder::XPath;
use HTTP::Request;

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

use ProductPicture;
use ProductDescriptionPicture;



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Product',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('IsNew', {
		Type => $ISoft::DB::TYPE_BIT,
		NotNull => 1,
		Default => 0
  });
 
  $self->addColumn('Title', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 4096
  });

  $self->addColumn('MetaK', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 4096
  });

  $self->addColumn('MetaD', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 4096
  });

  $self->addColumn('OuterPrice', {
		Type => $ISoft::DB::TYPE_MONEY
  });

  $self->addColumn('PriceFrom', {
		Type => $ISoft::DB::TYPE_BIT,
		Length => 1,
		NotNull => 1,
		Default => 1
  });

  return $self;
}

sub getPictures {
	my ($self, $dbh) = @_;
	
	my $pic = ProductPicture->new;
	$pic->set('Product_ID', $self->ID);
	$pic->maxReturn(12);
	my $reff = $pic->listSelect($dbh);
	return wantarray ? @$reff : $reff;
}

# for unexpected operations (price)
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	return unless $self->get('IsNew');
	return if $self->debug();
	
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
					my $price_obj = Price->new;
					$price_obj->set('URL', $pdf_url."&color=$color");
					$price_obj->set($parent, $self->ID);
					$price_obj->markDone();
					$price_obj->insert($dbh);
				}
			} else {
				# insert just one base price
				my $price_obj = Price->new;
				$price_obj->set('URL', $pdf_url);
				$price_obj->set($parent, $self->ID);
				$price_obj->markDone();
				$price_obj->insert($dbh);
			}
			
		}
	}
}

sub getExtraData {
	my($self, $tree) = @_;
	
	my @nodes = $tree->findnodes( q{/html/head/title} );
	my $title = $nodes[0]->as_text();
	
	@nodes = $tree->findnodes( q{/html/head/meta[@name="keywords"]} );
	my $keywords = $nodes[0]->attr('content');
	
	@nodes = $tree->findnodes( q{/html/head/meta[@name="description"]} );
	my $descr = $nodes[0]->attr('content');

	my %extra = (
		Title => $title,
		MetaK => $keywords,
		MetaD => $descr
	);
	
	return \%extra;
}

sub processExtra {
	my ($self, $dbh, $tree) = @_;
	my $extradata = $self->getExtraData($tree);
	$self->setByHash($extradata);
	if($self->debug()){
		$self->debugEcho("Product extra data:");
		$self->debugEcho($extradata);
	}
}

sub processContent {
	my ($self, $dbh, $tree) = @_;
	$self->processExtra($dbh, $tree);
	if($self->get("IsNew")){
		$self->SUPER::processContent($dbh, $tree);
	}
}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	my @piclist;
	
	my @nodes = $tree->findnodes( q{//div[@class='lil_pic_div']/span/a} );
	foreach my $node (@nodes){
		my $url = $node->findvalue( q{./@href} );
		push @piclist, {
			URL => $self->absoluteUrl($url)
		};
	}
	
	if(@piclist==0){
		# perhaps there is only one picture
		my $u2 = $tree->findvalue( q{//td[@class='content-text']/table[1]/tr[1]/td[1]/div[1]/span[@class='img']/a/@href} );
		if($u2){
			push @piclist, {
				URL => $self->absoluteUrl($u2)
			};
		}
	}

	if(@piclist==0){
		# perhaps there is only one picture
		my $u2 = $tree->findvalue( q{//td[@class='content-text']/table[1]/tr[1]/td[1]/div[1]/span[@class='img']/img[@id='big_pic']/@src} );
		if($u2){
			push @piclist, {
				URL => $self->absoluteUrl($u2)
			};
		}
	}

	# still no images, try another variant
	if(@piclist==0){
		my @rlist = $tree->findnodes( q{//a[@rel]} );
		foreach my $ritem (@rlist){
			my $rel = $ritem->findvalue( q{./@rel} );
			if($rel =~ /lightbox\[group\d+\]/){
				# bingo!
				push @piclist, {
					URL => $self->absoluteUrl($ritem->findvalue( q{./@href} ))
				};				
			}
		}
	}
	
	
	if(@piclist==0){
		my $u2 = $tree->findvalue( q{//td[@class='content-text']/table[1]/tr[1]/td[1]/div[1]/span[@class='img']/img[@id='big_pic']/@src} );
		if($u2){
			push @piclist, {
				URL => $self->absoluteUrl($u2)
			};
		}
	}

	if(@piclist==0){
		my $u2 = $tree->findvalue( q{//td[@class='content-text']/table[1]/tr[1]/td[1]/div[@class='rounded']/a/img[@id='big_pic']/@src} );
		if($u2){
			push @piclist, {
				URL => $self->absoluteUrl($u2)
			};
		}
	}
	
	return \@piclist;
}

sub descriptionNodeFilter {
	my ($self, $node) = @_;
	# remove forms and inputs
	my @bads = $node->findnodes( q{.//input} );
	foreach (@bads){
		$_->delete();
	}
	if($node->tag() eq 'div' && $node->attr('style') eq 'clear: both;'){
		my @sub = $node->findnodes( q{./span[@style='font-size: 21px;']} );
		return 0 if @sub>0;
	}
	return 1;
}


sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	my @clauses = (
		q{//td[@class='content-text']//div[@class='descript']},
		q{//td[@class='content-text']//div[@style='clear: both;']},
		q{//td[@class='content-text']//div[@id='category_content_1']},
		q{//td[@class='content-text']//div[@id='category_content_3']},
		q{//td[@class='content-text']//table[@id='bottom_colors']},
		q{//td[@class='content-text']/div[@class='item_category_title']},
		q{//td[@class='content-text']/div[@class='element_item']},
		
		q{//table[@class='behaviour']},
		q{//div[@class='furniture_list_container']/table[@class='cat4']},
		q{//div[@class='furniture_list_container']/table[@class='cat3']/tr[3]/td},
		
	);
	
	my $clause = join ' | ', @clauses;
	
	my @nodes = $tree->findnodes( $clause );
	
	return \@nodes;
}


sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	# may be we already have the description
	my $descr = $description || '';
	
	my %data = (
		Description => $descr
	);
	
	if($descr=~/<div><b>Производитель:\s<\/b><span>(.*?)<\/span><\/div>/){
		$data{Vendor} = $1;
	} elsif ($descr=~/<td class="l_c">Производитель:<\/td>\s*<td class="r_c">(.*?)<\/td>/){
		$data{Vendor} = $1;
	}

	if($descr=~/<span class="span_price">(.*?)<\/span>/){
		my $price = $1;
		$price =~ s/[^\d]//g;
		$data{Price} = $price;
	}
	
	return \%data;
	
}



1;
