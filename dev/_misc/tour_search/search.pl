use strict;
use warnings;

use utf8;

use YAML::Loader;

use Search::Query;



my $config = load_config('intourist');

my $obj = get_search_engine($config);


my $query1 = {
action2 => 'doPrice',
requestid => 0,
pagenum => 0,
resultcount => 0,
cmbCityFrom => 1623,
cmbCountry => '7-26',
cmbDates => '20.09.2010',
cmbHROrder => 2,
cmbPansion => 15,
#cmbSort => 1,
};

my $query = {
	city => 'Пермь',
	country => 'Таиланд',
	region => 'Бангкок, Паттайя',
	date => '17.02.2011'
};


$obj->prepare($query);
my $datalist = $obj->parse();


################################################################

sub load_config {
	my $name = shift;
	
	if ($name !~ /\./){
		$name .= '.yaml';
	}

	open XX, '<:encoding(UTF-8)', $name;
	my $buffer = '';
	while (<XX>){
	$buffer .= $_;
	}
	close XX;
	
	my $loader = YAML::Loader->new;
	return $loader->load($buffer);
	
}



