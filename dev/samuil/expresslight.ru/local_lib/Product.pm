package Product;

use strict;
use warnings;

use utf8;

use Error ':try';

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);


our $people_and_box = q{<table><tbody><tr><td><h3>Габариты относительно людей</h3><p><span id="human" style="font-size: small;">180 см.</span></p></td><td></td></tr><tr><td><img src="http://proartsvet.ru/published/publicdata/PROART24SHOP/attachments/SC/images/siluets.JPG" height="180" width="121" /><img src="http://proartsvet.ru/published/publicdata/PROART24SHOP/attachments/SC/images/box.jpg" height="-!h!-" width="-!w!-" /></td><td></td></tr></tbody></table><p><span><br /></span></p> };

our %mapping = (
	'Фабрика:' => 'Vendor',
	'Производство:' => 'Production',
	'Арматура:' => 'Armature',
	'Высота:' => 'Height',
	'Высота встраиваемой части:' => 'HeightOfInnerPart',
	'Диаметр врезного отверстия:' => 'InnerDiameter',
	'Диаметр:' => 'Diameter',
	'Тип цоколя:' => 'LampBaseType',
	'Лампы:' => 'Lamps',
	'Ширина:' => 'Width',
	'Длина:' => 'Length',
	'Глубина:' => 'Depth',
	'Класс защиты:' => 'ProtectionClass',
	'IP:' => 'IP',
);

our @short_description_content = (
	['Артикул товара:', 'ProductCode'],
	['Фабрика:', 'Vendor', 'vlink'],
	['Производство:', 'Production', 'Production'],
	['Арматура:', 'Armature', 'Armature'],
	['Высота:', 'Height'],
	['Диаметр:', 'Diameter'],
	['Ширина:', 'Width'],
	['Глубина:', 'Depth'],
	['Тип цоколя:', 'LampBaseType'],
	['Лампы:', 'Lamps'],
);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  descriptionpictures => 0,
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
  $self->addColumn('Armature', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 100,
  });

  $self->addColumn('Production', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 50,
  });

  $self->addColumn('Height', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('HeightOfInnerPart', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('InnerDiameter', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });
  
  $self->addColumn('Diameter', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('LampBaseType', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 30,
  });

  $self->addColumn('Lamps', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 50,
  });

  $self->addColumn('Width', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('Length', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('Depth', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('ProtectionClass', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('IP', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 20,
  });

  $self->addColumn('ProductLine', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  $self->addColumn('ProductCode', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 50,
  });

  return $self;
}

sub text2cm {
	my $txt = shift;
	if($txt=~/(\d+)\s*, мм/){
		return $1 / 10;
	}elsif($txt=~/([0-9,]+)см(|\(основание\)), мм/){
		my $sm = $1;
		$sm =~ s/,/./;
		return $sm;
	} else {
		die "Bad text: $txt";
	}
}

sub getBox {
	my $self = shift;
	
	my $box = '';
	
	try {
		
		my $height = $self->get("Height");
		my $width = $self->get("Width") || $self->get("Diameter");
		
		if($width && $height){
			my $h = text2cm($height);
			my $w = text2cm($width);
			
			my $bh = int( 180 * ( $h / 180 ) );
			my $ratio = $bh / $h;
			my $bw = int( $w * $ratio );
			
			$box = $people_and_box;
			$box =~ s/-!w!-/$bw/;
			$box =~ s/-!h!-/$bh/;
		}

	} otherwise {
		die "Box failed in product ".$self->ID;
		
	};
	
	return $box;
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
	
	my @nodes = $tree->findnodes( q{//div[@class='tovar-image']/a/img} );
	
	# contains url list, each is the scalar
	my @piclist;
	
	if(@nodes>0){
		push @piclist, $self->absoluteUrl( $nodes[0]->findvalue('./@src') );
	}
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @list;
	
	my @datalist = $tree->findnodes( q{.//div[@class="tovar"]/*} );
	# remove the first paragraph (empty)
	shift @datalist;
	# remove product details table
	pop @datalist;
	
	if (@datalist > 0){
		# copy to result
		@list = @datalist;
	}

	return \@list;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	# internal ID
	my @meta = $tree->findnodes( q{//meta[@name="keywords"]} );
	$data{InternalID} = $meta[0]->attr('content');
	
	my $container = $tree->findnodes( q{//div[@class="content-in-right"]} )->get_node(1);
	
	# name
	$data{Name} = $container->findvalue( './h1' );
	
	# price
	$data{Price} = $container->findvalue( './/div[@class="tovar-price"]/span' );
	$data{Price} =~ s/\s//g;
	$data{Price} = 0 unless $data{Price};
	
	# decode other parameters
	my @datalist = $container->findnodes( q{.//div[@class="tovar-text"]//tr} );
	foreach my $item (@datalist){
		my $key = $item->findvalue( q{./td[1]} );
		my $val = $item->findvalue( q{./td[2]} );
		$val =~ s/^\s+//;
		$val =~ s/\s+$//;
		$self->debugEcho( "No mapping for $key" )unless exists $mapping{$key};
		die "No mapping" unless exists $mapping{$key};
		$data{ $mapping{$key} } = $val;
	}

	# product line
	my @others = $container->findvalues( q{.//div[@class="prep-a"]/a/@href} );
	$data{ProductLine} = join '-!-', @others;
	
	return \%data;
}





1;
