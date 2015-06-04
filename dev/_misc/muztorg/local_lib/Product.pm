package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new( @_ );

	# create additional columns
	
  $self->addColumn('ShortDescription', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  $self->addColumn('LongDescription', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

	$self->removeColumn('Description');


  return $self;
}


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

# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	# contains url list, each is the scalar
	my @piclist;
	
	my $val = $tree->findvalue( q{//div[@class='picture']/a/@href} );
	if($val=~/view\.php\?pic=(.*)/){
		push @piclist, $self->absoluteUrl('/'.$1);
	}
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data;
	
	my @data1 = $tree->findnodes( q{//div[@class='about']/div[@class='name']} );
	my $node = shift @data1;
	
	#$data{Name} = $node->findvalue( q{./h1} );
	$data{ShortDescription} = $node->findvalue( q{./span[@class='d']} );
	my $article = $node->findvalue( q{./span[@class='d stt']} );
	if($article){
		$article =~ s/.*: //;
		$data{InternalID} = $article;
	}
	
	my $price = $node->findvalue( q{//div[@class='int_price']} );
	if($price){
		$price=~s/\D//g;
		$data{Price} = $price;
	}
	
	my $long = ($node->findnodes( q{//div[@class='spec_desc_inner']/div[@class='d']} ))[0];
	if($long){
		$data{LongDescription} = $self->asHtml($long);
	}
	
	return \%data;
}





1;
