package Product;

use strict;
use warnings;

use utf8;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  descriptionpictures => 0,
  );
  
  my $self = $class->SUPER::new(%params, @_);

  $self->addColumn('Properties', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

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
	
	my @piclist = map { $self->absoluteUrl($_) } $tree->findvalues( q{//div[@class='unbelievable']//img/@src} );
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list = $tree->findnodes( q{//div[@class='main_descr']} );
	
	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	# price
	my $price = $tree->findvalue( q{//div[@class='actualcost']} );
	$price =~ s/\.–.*//;
	$price =~ s/\D//g;
	
	$data{Price} = $price;
	
	# name
	my $name = $tree->findvalue( q{//div[@class='contentname']/h1} );
	$data{Name} = $name;
	
	# properties
	my $pr = ( $tree->findnodes( q{//div[@id='full_desc']} ) )[0];
	$data{Properties} = $self->asHtml($pr);
	
	return \%data;
}





1;
