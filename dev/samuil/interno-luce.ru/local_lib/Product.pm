package Product;

use strict;
use warnings;

use utf8;

use Error ':try';

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);

our $people_and_box = q{<table><tbody><tr><td><h3>Габариты относительно людей</h3><p><span id="human" style="font-size: small;">180 см.</span></p></td><td></td></tr><tr><td><img src="http://proartsvet.ru/published/publicdata/PROART24SHOP/attachments/SC/images/siluets.JPG" height="180" width="121" /><img src="http://proartsvet.ru/published/publicdata/PROART24SHOP/attachments/SC/images/box.jpg" height="-!h!-" width="-!w!-" /></td><td></td></tr></tbody></table><p><span><br /></span></p> };

our @all_properties = (
	{	name => 'Артикул товара',
		inprod => 1,
		field => 'ProductCode'
	},
	{	name => 'Фабрика',
		inprod => 1,
		field => 'Vendor'
	},
	{	name => 'Производство',
		inprod => 0,
		tagged => 1,
	},
	{	name => 'Материалы',
		inprod => 0,
		tagged => 1,
	},
	{	name => 'Высота',
		inprod => 0
	},
	{	name => 'Диаметр',
		inprod => 0
	},
	{	name => 'Ширина',
		inprod => 0
	},
	{	name => 'Длина',
		inprod => 0
	},
	{	name => 'Тип цоколя',
		inprod => 0
	},
	{	name => 'Акция',
		inprod => 0
	},
	{	name => 'Экономия',
		inprod => 0
	},
	{	name => 'Вес',
		inprod => 0
	},
	{	name => 'Выступ от стены',
		inprod => 0
	},
	{	name => 'Мощность ламп',
		inprod => 0
	},
	{	name => 'Количество ламп',
		inprod => 0
	},
);

our @brief_content = (
	{	name => 'Артикул товара',
		inprod => 1,
		field => 'ProductCode'
	},
	{	name => 'Фабрика',
		inprod => 1,
		field => 'Vendor'
	},
	{	name => 'Производство',
		inprod => 0,
		tagged => 1,
	},
	{	name => 'Материалы',
		inprod => 0,
		tagged => 1,
	},
	{	name => 'Высота',
		inprod => 0
	},
	{	name => 'Диаметр',
		inprod => 0
	},
	{	name => 'Ширина',
		inprod => 0
	},
	{	name => 'Тип цоколя',
		inprod => 0
	},
	{	name => 'Мощность ламп',
		inprod => 0
	},
	{	name => 'Количество ламп',
		inprod => 0
	},
);


sub getBox {
	my ($self, $property) = @_;
	
	my $box = '';
	
	try {
		
		my $height = $property->{Высота};
		my $width = $property->{Ширина} || $property->{Диаметр};
		
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

sub text2cm {
	my $txt = shift;
	if($txt=~/(\d+)\s*, мм/){
		return $1 / 10;
	}elsif($txt=~/([0-9,]+)см(|\(основание\)), мм/){
		my $sm = $1;
		$sm =~ s/,/./;
		return $sm;
	}elsif($txt=~/^(\d+) см\.$/){
		return $1;
	}elsif($txt=~/^(\d+([.,]\d+|))\+(\d+)\s*см\.$/){
		# x+y sm.
		my $x = $1;
		my $y = $3;
		$x=~s/,/./;
		return $x+$y;
	}elsif($txt=~/^(\d+(\.\d+|))\/(\d+) см\.$/){
		return $1 > $3 ? $1 : $3;
	}elsif($txt=~/^(\d+)-(\d+) см\.$/){
		return $1 > $2 ? $1 : $2;
	} else {
		print "Bad text: $txt\n";
		die;
	}
}

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  );
  
  my $self = $class->SUPER::new(%params, @_);

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

  $self->addColumn('ProductLine', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 2000,
  });

  $self->addColumn('ProductCode', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250,
  });

  return $self;
}


1;
