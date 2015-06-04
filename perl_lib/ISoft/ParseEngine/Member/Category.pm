package ISoft::ParseEngine::Member::Category;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use HTTP::Request;

use ISoft::Exception::ScriptError;

use ISoft::ParseEngine::Member::File::CategoryPicture;
use ISoft::ParseEngine::Member::Product;

# base class
use base qw(ISoft::ParseEngine::Member);



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Category',
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Category_ID', {
  	Type => $ISoft::DB::TYPE_INT,
  	ForeignTable => 'Category',
  	ForeignKey => 'ID'
  });

  $self->addColumn('Level', {
		Type => $ISoft::DB::TYPE_INT,
		Index => 1,
		Default => 0
  });
  
  $self->addColumn('Page', {
		Type => $ISoft::DB::TYPE_SMALLINT,
		NotNull => 1,
		Default => 1,
  });

  $self->addColumn('Name', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250
  });

  $self->addColumn('Description', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  return $self;
}

# returns an instance of a class representing CategoryPicture.
# override the function for using another class.
sub newCategoryPicture {
	my $self = shift;
	return ISoft::ParseEngine::Member::File::CategoryPicture->new;
}

# returns an instance of a class representing Product.
# override the function for using another class.
sub newProduct {
	my $self = shift;
	return ISoft::ParseEngine::Member::Product->new;
}


sub extractNextPage {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return '';	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	my @list;
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	my @list;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \@list;
}

sub processCategoryDescription {
	my ($self, $dbh, $tree) = @_;
	my $description = $self->extractDescription($tree);
	if ($description){
		if ($self->debug()){
			$self->debugEcho('Description: '.$description);
		} else {
			$self->set('Description', $description);
		}
	}
}

sub processSubCategories {
	my ($self, $dbh, $tree) = @_;
	my $count = 0;
	my $data = $self->extractSubCategoriesData($tree);
	if($self->debug()){
		$self->debugEcho("Subcategories:");
		$self->debugEcho($data);
	} else {
		my $id = $self->ID;
		my $level = $self->get('Level') + 1;
		foreach my $item (@$data){
			# the 'Picture' key is reserved for a category picture
			my $pic = delete $item->{Picture};
			my $obj = $self->new;
			$obj->setByHash($item);
			$obj->set('Category_ID', $id);
			$obj->set('Level', $level);
			$obj->insert($dbh);
			if(defined $pic){
				my $pic_obj = $self->newCategoryPicture();
				$pic_obj->set('Category_ID', $obj->ID);
				$pic_obj->set('URL', $pic);
				$pic_obj->insert($dbh);
			}
		}
	}
	
	return scalar @$data;
}

sub insertProducts {
	my ($self, $dbh, $data) = @_;
	
	foreach my $dataitem (@$data){
		my $obj = $self->newProduct();
		$obj->set('Category_ID', $self->ID);
		$obj->setByHash($dataitem);
		$obj->insert($dbh);
	}
	
}

sub processProducts {
	my ($self, $dbh, $tree) = @_;
	
	my $data = $self->extractProducts($tree);
	if($self->debug()){
		$self->debugEcho("Products:");
		$self->debugEcho($data);
	} else {
		$self->insertProducts($dbh, $data);
	}
	
	return scalar @$data;
}

sub processContent {
	my ($self, $dbh, $tree) = @_;
	
	# look for sub-categories, but only if it is the first page
	my $sc_count = 0;
	my $page = $self->get('Page');
	if($page==1){
		# extract description, but only if the description is not exist yet
		$self->processCategoryDescription($dbh, $tree) unless $self->get('Description');
		# extract sub categories
		$sc_count = $self->processSubCategories($dbh, $tree);
	}

	# look for products, but only if there are no sub categories
	my $p_count = 0;
	if($sc_count == 0){
		$p_count = $self->processProducts($dbh, $tree);
	}

	# look for the next page, but only if there are products
	if(($p_count > 0) && (my $nextpage = $self->extractNextPage($tree))){
		if($self->debug()){
			$self->debugEcho("Next page: $nextpage");
		}
		$self->set('URL', $nextpage);
		$self->set('Page', $page+1);
		$self->markNew();
	}
	
}

sub getPicture {
	my ($self, $dbh) = @_;
	
	my $pic = $self->newCategoryPicture();
	$pic->set('Category_ID', $self->ID);
	if($pic->checkExistence($dbh)){
		return $pic;
	} else {
		return undef;
	}
	
}


sub getCategories {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = $self->new();
	$obj->set('Category_ID', $self->ID);
	$obj->markDone();
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}

sub getProducts {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = $self->newProduct();
	$obj->set('Category_ID', $self->ID);
	$obj->markDone();
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}

1;
