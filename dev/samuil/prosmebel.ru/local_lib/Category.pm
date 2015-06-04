package Category;

use strict;
use warnings;

use Product;
use CategoryPicture;

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Category);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new(@_);

	# create additional columns
	
  $self->addColumn('PageTitle', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });

  $self->addColumn('PageMetakeywords', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });

  $self->addColumn('PageMetaDescription', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000
  });

  $self->addColumn('Flag', {
		Type => $ISoft::DB::TYPE_TINYINT,
		NotNull => 1
  });

  return $self;
}

sub getUnexportedProducts {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = $self->newProduct();
	$obj->set('Category_ID', $self->ID);
	$obj->set('Exported', 0);
	$obj->markDone();
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}

# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
sub newCategoryPicture {
	my $self = shift;
	return CategoryPicture->new;
}

sub getCategoryPicture {
	my ($self, $dbh) = @_;
	
	my $cp_obj = $self->newCategoryPicture();
	$cp_obj->set("Category_ID", $self->ID);
	$cp_obj->markDone();
	if($cp_obj->checkExistence($dbh)){
		return $cp_obj;
	}
	return undef;
	
}

sub getAlias {
	my $self = shift;
	if($self->{alias}){
		return $self->{alias};
	}
	my $url = $self->get("URL");
	$url =~ s|http://www.prosmebel\.ru/||;
	$url =~ s|/|_|g;
	$self->{alias} = $url;
	return $url;
}

# change class name for using another class.
# or just remove the function if the standard class is ok for you.
sub newProduct {
	my $self = shift;
	return Product->new;
}


# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}


sub extractNextPage {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	my $page = '';	
	my @pagers = $tree->findnodes( q{//div[@class='pages']} );
	if(@pagers>0){
		my $pager = shift @pagers;
		$page = $pager->findvalue( q{./span/following-sibling::a[1]/@href} );
		$page = $page ? $self->absoluteUrl($page) : '';
	}
	return $page;	
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
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	my @list;
	
	my @nodes = $tree->findnodes( q{} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		# the 'Picture' key is reserved for the category picture
		#$h{Picture} = $self->absoluteUrl( $node->findvalue( q{} ) );
		push @list, \%h;
		
	}

	return \@list;
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	my @list;
	
	my @nodes = $tree->findnodes( q{} );
	foreach my $node (@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} );
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
