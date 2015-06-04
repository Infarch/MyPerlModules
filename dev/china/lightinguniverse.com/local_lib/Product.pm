package Product;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;
use Manual;
use Property;
use ProductPicture;

# base class
use base qw(ISoft::ParseEngine::Member::Product);


sub trim ($) {
	my $x = shift;
	if($x){
		$x =~ s/^\s+//;
		$x =~ s/\s+$//;
	}
	return $x;
}

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  descriptionpictures => 0,
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns

  $self->addColumn('Code', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 10
  });

  $self->addColumn('Style', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 50
  });

  $self->addColumn('ListPrice', {
		Type => $ISoft::DB::TYPE_REAL,
  });

  $self->addColumn('MaxPrice', {
		Type => $ISoft::DB::TYPE_REAL,
  });

  $self->addColumn('FreeShipping', {
		Type => $ISoft::DB::TYPE_BIT,
		Length => 1
  });

  $self->addColumn('InStock', {
		Type => $ISoft::DB::TYPE_BIT,
		Length => 1
  });

  $self->addColumn('NewDescription', {
		Type => $ISoft::DB::TYPE_LONGTEXT,
  });

  $self->addColumn('Collection', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 200
  });

  $self->addColumn('Returnable', {
		Type => $ISoft::DB::TYPE_BIT,
		Length => 1
  });

  $self->addColumn('DestinationCode', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 10
  });

  $self->addColumn('Processed', {
		Type => $ISoft::DB::TYPE_BIT,
		Length => 1
  });

  return $self;
}

sub getMD5 {
	my ($self) = @_;
	
	return $self->{md5} if exists $self->{md5};
	
	my $key = md5_hex($self->get('URL'));
	$self->{md5} = $key;
	return $key;
}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
sub newProductPicture {
	my $self = shift;
	return ProductPicture->new(cache=>0);
}

# for unexpected operations
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	# extract manuals
	my @nodes = $tree->findnodes( q{//div[@id="Main_productPage_manuals"]/div/a} );
	foreach my $node (@nodes){
		
		my $name = $node->findvalue( '.' );
		my $href = $node->findvalue( './@href' );
		
		my $manual = Manual->new;
		$manual->set('Product_ID', $self->ID);
		$manual->set('Name', $name);
		$manual->set('URL', $href);
		$manual->insert($dbh);
		
	}
	
	
}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	my %imgs;
	
	# main image
	my $main_zoom = $tree->findnodes( q{//img[@id="imgZoom"]} )->get_node(1)->findvalue( './@src' );
	my $main_org = $tree->findnodes( q{//div[@id="divMainImg"]/img[@id="imgProduct"]} )->get_node(1)->findvalue( './@src' );
	my $main = $main_zoom || $main_org;
	if($main){
		$main =~ s/^\/\//http:\/\//;
		$imgs{ $main } = 'main';
	}
	
	# get additional images
	my @adds = $tree->findvalues( q{//div[@class="altImg"]/img/@onmouseover} );
	foreach my $add (@adds){
		if($add =~ /viewPageSwapImage\('([^']+)'/) #'
		{
			$add = $1;
			$add =~ s/^\/\//http:\/\//;
			$imgs{$add} = 1;
			$add =~ s/\/img\/[^\/]+\//\/img\/x\//;
			$imgs{$add} = 1;
		}
	}
	my @piclist = keys %imgs;
	return \@piclist;
}

sub extractDescriptionNodes {
	return [];
}

sub processProductData {
	my ($self, $dbh, $tree, $description) = @_;
	
	my $data = $self->extractProductData($dbh, $tree, $description);
	$self->setByHash($data);
	if($self->debug()){
		$self->debugEcho("Product data:");
		$self->debugEcho($data);
	}
}

sub extractProductData {
	my ($self, $dbh, $tree, $description) = @_;
	
	my %properties;
	my $setproperty = sub {
		my $n = trim(shift);
		my $v = trim(shift);
		if($n && $v){
			$n = 'Shade' if $n eq 'shade';
			$n=~s/\s|\/|\(|\)|-//g;
			my $prop = Property->new;
			$prop->set('Product_ID', $self->ID);
			$prop->set('Name', $n);
			$prop->set('Value', $v);
			$prop->insert($dbh, 1);
		}
	};
	
	# main properties
	$properties{Name} = $tree->findvalue( q{//h1[@itemprop="name"]} );
	$properties{Vendor} = $tree->findvalue( q{//a[@itemprop="manufacturer"]} );
	$properties{Description} = $tree->findvalue( q{//div[@id="prodDesc"]/div[@itemprop="description"]} );
	$setproperty->('Price', $tree->findvalue( q{//div[@id="divPrice"]} ) );
	
	# process dimensions
	my @rows = $tree->findnodes( q{//table[@id="tblDim"]/tr} );
	foreach my $row (@rows){
		my $name = $row->findvalue( q{./td[1]} );
		my $value = $row->findvalue( q{./td[2]} );
		$setproperty->($name, $value);
	}

	# process selectable options
	my @opts = $tree->findnodes( q{//div[@id="tblCart"]/div[@class="fntsb cg"] | //div[@id="tblCart"]/select} );
	my $opt_name;
	foreach my $opt (@opts){
		if($opt->tag() eq 'div'){
			$opt_name = $opt->findvalue('.');
		} else {
			my @options = $opt->findvalues('./option');
			shift @options; # the first option is always 'Select'
			$setproperty->($opt_name, join '-!-', map { trim($_) } @options);
		}
	}
	
	# process static options
	my @staticopts = $tree->findnodes( q{//div[@id="prodDesc"]/table[@class="cfl"]/tr} );
	foreach my $staticopt (@staticopts){
		my $name = $staticopt->findvalue( q{./td[1]} );
		my $value = $staticopt->findvalue( q{./td[2]} );
		$value =~ s/\[[^\]]+\]$//;
		$value =~ s/^\s,//;
		$setproperty->($name, $value);
	}
	
	# product code
	$properties{InternalID} = trim $tree->findnodes( q{//td[@id="tdMfrProdId"]} )->get_node(1)->findvalue( '.' );
	
	# has bulb
	my $bi;
	my $div = $tree->findnodes( q{//div[@class="strong crd sprite-nobulb"]} )->get_node(1);
	if($div){
		$bi = $div->findvalue( '.' );
	} else {
		$div = $tree->findnodes( q{//div[@class="sprite-bulb"]/strong} )->get_node(1);
		if($div){
			$bi = $div->findvalue( '.' );
		}
	}
	
	$setproperty->('HasBulb', $bi);
	
	
	
	return \%properties;
}





1;
