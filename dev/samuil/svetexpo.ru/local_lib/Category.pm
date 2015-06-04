package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use Product;




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

  return $self;
}



# returns an instance of a class representing CategoryPicture.
# uncomment and override the function for using another class.
#sub newCategoryPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::CategoryPicture->new;
#}

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
	my $node = $tree->findnodes( q{//div[@class="cont_bl_m"]} )->get_node(0);
	return $node ? $self->asHtml($node) : '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	
	
	my @nodes;
	my $level = $self->get('Level');
	if($level == 0){
		# two main options
		@nodes = $tree->findnodes( q{//li[@class="lev_1"]/a[1]} );
	}else{
		# we MUST take into account what category we are in
		if($self->get('URL') =~ /katalog\/interernye-svetilniki/){
			# interior lamps
			$level++;
			my $ul = $tree->findnodes( q{//ul[@class="left_menu"]} )->get_node(1);
			my $query = './li[@class="lev_'.$level.'"]/a[1]';
			@nodes = $ul->findnodes( $query );
		} else {
			# outdoor lamps
			# only one sub category level
			if($level==1){
				@nodes = $tree->findnodes( q{.//div[@class="cat-cap"]/a} );
			}
		}
	}
	
	my @list;

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
	
	my @list;
	
	my @nodes = $tree->findnodes( q{//div[@class="sproduct"]/a[@href]} );
	foreach my $node (@nodes){
		my %h;
		
		my $th = $node->findvalue( q{./img/@src} );
		$th=~s/[\r\n]//g;
		$h{Thumbnail} = $self->absoluteUrl( $th );
		
		$h{URL} = $self->absoluteUrl( $node->findvalue( q{./@href} ) );
		push @list, \%h;
		
	}

	return \@list;
}



1;
