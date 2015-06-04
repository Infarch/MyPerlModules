package Product;

use strict;
use warnings;


use constant STATUS_NORMAL_PICTURE  => 10;
use constant STATUS_ASIS_PICTURE  => 11;


use utf8;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

use AssemblyManual;

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new( @_ );

	# create additional columns
	
  $self->addColumn('RawPage', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

  return $self;
}

# returns also the product description html
sub processProductDescription {
	my ($self, $dbh, $tree) = @_;
	
	my $html = '';
	my @debug;
	my @mans;
	my %man_registry;
	
	# look for description node(s)
	my $nodes = $self->extractDescriptionNodes($tree);
	foreach my $node (@$nodes){
		
		# user defined function performing pre-process of description nodes
		next unless $self->descriptionNodeFilter($node);
		
		# process each the 'img' tag within the node
		my @pictures = $node->findnodes( q{.//img} );
		foreach my $picture (@pictures){
			my $url = $picture->findvalue( q{./@src} );
			next unless $url;
			$url = $self->absoluteUrl($url);
			my $id;
			if($self->debug()){
				$id = 666;
				push @debug, $url;
			} else {
				$id = $self->insertDescriptionPicture($dbh, $url);
			}
			$picture->attr('isoft:id', $id);
		}

		# look for manual
		my @manuals = grep { $_->attr('href')=~/\.pdf$/i } $node->findnodes( q{.//a} );
		foreach my $manual (@manuals){
			my $url = $manual->attr('href');
			$url = $self->absoluteUrl($url);
			next if exists $man_registry{$url};
			$man_registry{$url} = 1;
			my $id;
			if($self->debug()){
				$id = 777;
				push @mans, $url;
			} else {
				$id = $self->insertManual($dbh, $url);
			}
			$manual->attr('isoft:id', $id);
		}


		# append the node's html to collector
		$html .= $self->asHtml($node);
	}
	
	if($self->debug()){
		$self->debugEcho("DescriptionPictures:");
		$self->debugEcho(\@debug);
		$self->debugEcho("Manuals:");
		$self->debugEcho(\@mans);
	}
	
	return $html;
}

sub insertManual {
	my ($self, $dbh, $url) = @_;
	
	my $manual_obj = AssemblyManual->new;
	$manual_obj->set('Product_ID', $self->ID);
	$manual_obj->set('URL', $url);
	$manual_obj->insert($dbh);
	
	return $manual_obj->ID;
	
}

sub processContent {
	my ($self, $dbh, $tree) = @_;

	$self->SUPER::processContent($dbh, $tree);
	$self->set('RawPage', $self->asHtml($tree));
	
}

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
sub descriptionNodeFilter {
	my ($self, $node) = @_;
	# remove inputs
	my @bads = $node->findnodes( q{.//input} );
	foreach (@bads){
		$_->delete();
	}
	@bads = $node->findnodes( q{.//img[@alt='Увеличить']} );
	foreach (@bads){
		$_->delete();
	}
	
	return 1;
}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	my @piclist;
	
	my $pp_obj = $self->newProductPicture();
	
	# type NORMAL
	my @normal_list = $tree->findnodes( q{//table[@id='table1']/tr[1]/td[2]/div/div} );
	foreach my $normal_item (@normal_list){
		my $url = $normal_item->findvalue( q{./a/@href} );
		push @piclist, {
			URL => $self->absoluteUrl($url),
			Type => $pp_obj->TYPE_NORMAL
		};
	}
	
	# type ASIS
	my $asis_item = $tree->findvalue( q{//table[@id='table1']/tr[1]/td[1]/div/a/img/@src} );
	push @piclist, {
		URL => $self->absoluteUrl($asis_item),
		Type => $pp_obj->TYPE_ASIS
	};
	
	# type COLOR
	my @color_list = $tree->findnodes( q{//div[@style='float:left; padding: 0px 0px 30px 0px; position: relative; width: 115px;']} );
	foreach my $color_item (@color_list){
		# check the lense
		my $color = $color_item->findvalue( q{./div[2]/a/@href} );
		next unless $color;
		
		my $url = $self->absoluteUrl($color);
		push @piclist, {
			URL => $url,
			Type => $pp_obj->TYPE_COLOR
		};
		
	}
	
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list = $tree->findnodes( q{/html/body/div[2]/div[2]/div[3]} );
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	my $name = $tree->findvalue( q{//p[@class='good_name']} );
	my $price = $tree->findvalue( q{//div[@class='txt']/table/tr[2]/td[1]/p} );
	$price =~ s/\D//g;
	
	$data{Name} = $name;
	$data{Price} = $price;
	
	return \%data;
}





1;
