package ISoft::ParseEngine::Member::Product;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use HTTP::Request;

use ISoft::Exception::ScriptError;

use ISoft::ParseEngine::Member::File::ProductPicture;
use ISoft::ParseEngine::Member::File::ProductDescriptionPicture;


# base class
use base qw(ISoft::ParseEngine::Member);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Product',
	  descriptionpictures => 1,
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Category_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Category',
  	ForeignKey => 'ID'
  });

  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  $self->addColumn('Description', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

  $self->addColumn('ShortDescription', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  $self->addColumn('Vendor', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 100,
  });

  $self->addColumn('Price', {
		Type => $ISoft::DB::TYPE_MONEY,
		Default => 0,
  });

  $self->addColumn('InternalID', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 100,
  });


  return $self;
}

# returns an instance of a class representing ProductDescriptionPicture.
# override the function for using another class.
sub newProductDescriptionPicture {
	my $self = shift;
	return ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new;
}

# returns an instance of a class representing ProductPicture.
# override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ISoft::ParseEngine::Member::File::ProductPicture->new;
}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	my @piclist;
	
	# extract main picture
	
	# extract additional pictures
	
	#my @piclist = map { $self->absoluteUrl($_) } $tree->findvalues( q{} );
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	# may be you will need 'use utf8';
	
	my %data;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \%data;
}

sub descriptionNodeFilter {
	my ($self, $node) = @_;
	# to be overriden in children
	return 1; # or 0 if you want to skip the node
}

sub insertProductPictures {
	my ($self, $dbh, $listref) = @_;
	my $id = $self->ID;
	foreach my $item (@$listref){
		my $obj = $self->newProductPicture();
		$obj->set('Product_ID', $id);
		if(ref $item){
			if(ref $item eq 'HASH'){
				$obj->setByHash($item);
			} else {
				throw ISoft::Exception::ScriptError(message=>'Must be a HASH reference');
			}
		} else {
			# not a reference, consider as an url
			$obj->set('URL', $item);
		}
		$obj->insert($dbh, 1);
	}
}


sub processProductPictures {
	my ($self, $dbh, $tree) = @_;
	my $listref = $self->extractProductPictures($tree);
	if ($self->debug()){
		$self->debugEcho("Product picture(s):");
		$self->debugEcho($listref);
	} else {
		$self->insertProductPictures($dbh, $listref);
	}
}

# returns also the product description html
sub processProductDescription {
	my ($self, $dbh, $tree) = @_;
	
	my $html = '';
	my @debug;
	
	# look for description node(s)
	my $nodes = $self->extractDescriptionNodes($tree);
	foreach my $node (@$nodes){
		
		# user defined function performing pre-process of description nodes
		next unless $self->descriptionNodeFilter($node);
		
		if($self->{descriptionpictures}){
			# process each the 'img' tag within the node
			# take also into account that the node may be IMG itself
			my @pictures;
			if($node->tag() eq "img"){
				push @pictures, $node;
			} else {
				@pictures = $node->findnodes( q{.//img} );
			}
			foreach my $picture (@pictures){
				my $url = $picture->findvalue( q{./@src} );
				next unless $url;
				next if $url =~ /^[data:|chrome:]/i;
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
		}
		# append the node's html to collector
		$html .= $self->asHtml($node);
	}
	
	if($self->debug()){
		$self->debugEcho("DescriptionPictures:");
		$self->debugEcho(\@debug);
	}

	return $html;
}

sub insertDescriptionPicture {
	my ($self, $dbh, $url) = @_;
	
	my $obj = $self->newProductDescriptionPicture();
	$obj->set('Product_ID', $self->ID);
	$obj->set('URL', $url);
	$obj->insert($dbh);
	
	return $obj->ID;
}

sub processProductData {
	my ($self, $dbh, $tree, $description) = @_;
	
	my $data = $self->extractProductData($tree, $description);
	$self->setByHash($data);
	if($self->debug()){
		$self->debugEcho("Product data:");
		$self->debugEcho($data);
	}
}

sub processContent {
	my ($self, $dbh, $tree) = @_;

	$self->processProductPictures($dbh, $tree);
	my $d_html = $self->processProductDescription($dbh, $tree);
	$self->processProductData($dbh, $tree, $d_html);
}

sub getProductPictures {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = $self->newProductPicture();
	$obj->set('Product_ID', $self->ID);
	$obj->markDone();
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}

sub getProductDesriptionPictures {
	my ($self, $dbh) = @_;
	
	my $obj = $self->newProductDescriptionPicture();
	$obj->set('Product_ID', $self->ID);
	$obj->markDone();
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}






1;
