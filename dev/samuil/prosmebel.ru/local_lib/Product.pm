package Product;

use strict;
use warnings;


use ISoft::Exception::ScriptError;

use ModuleChapter;
use ProductPicture;
use ProductColor;
use ProductTable;
use ProductUpholstery;
use Upholstery;
use Advice;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

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

  $self->addColumn('Description2', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

  $self->addColumn('Avail', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 128
  });

  $self->addColumn('Production', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 100
  });

  $self->addColumn('Exported', {
		Type => $ISoft::DB::TYPE_BIT,
		NotNull => 1,
		Length => 1
  });

#  $self->addColumn('Advice', {
#		Type => $ISoft::DB::TYPE_VARCHAR,
#		Length => 250
#  });

#  $self->addColumn('AdvicedName', {
#		Type => $ISoft::DB::TYPE_VARCHAR,
#		Length => 250
#  });

  return $self;
}

sub getAdvices {
	my($self, $dbh) = @_;
	my $adv = Advice->new;
	$adv->set("Product_ID", $self->ID);
	my @list = $adv->listSelect($dbh);
	return @list
}

sub getUpholsteries {
	my($self, $dbh) = @_;
	my @list;
	my $pu = ProductUpholstery->new;
	$pu->set("Product_ID", $self->ID);
	my @ids = map { $_->get("Upholstery_ID") } $pu->listSelect($dbh);
	if(@ids){
		my $u = Upholstery->new;
		$u->set("ID", \@ids);
		@list = $u->listSelect($dbh);
	}
	return @list
}

sub getModuleChapters {
	my($self, $dbh) = @_;
	my $mc = ModuleChapter->new;
	$mc->set("Product_ID", $self->ID);
	return $mc->listSelect($dbh);
}

sub getColors {
	my($self, $dbh) = @_;
	my $c = ProductColor->new;
	$c->set("Product_ID", $self->ID);
	return $c->listSelect($dbh);
}

sub getAlias {
	my $self = shift;
	if($self->{alias}){
		return $self->{alias};
	}
	my $url = $self->get("URL");
	$url =~ s|http://www.prosmebel\.ru/||;
	$url =~ s|/|_|g;
	
	$url =~ s/aksessuary/aksessuar/g;
	
	$self->{alias} = $url;
	return $url;
}

sub getTableData {
	my($self, $dbh) = @_;
	my $obj = ProductTable->new;
	$obj->set("Product_ID", $self->ID);
	return $obj->listSelect($dbh);
}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ProductPicture->new;
}


sub extractProductPictures {
	my ($self, $tree) = @_;
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	# contains url list, each is the scalar
	my @piclist;
	
	# extract main picture
	
	# extract additional pictures
	
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
	
	my %data = (Description => $description);
	
	throw ISoft::Exception::ScriptError(message=>"Is not implemented");
	
	return \%data;
}





1;
