use strict;
use warnings;

use utf8;

use Encode qw/encode decode/;

use lib ("/work/perl_lib");
use ISoft::ParseEngine::ThreadProcessor;

use Product;





my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
my $dbh = $tp->getDbh();


my @list = Product->new->set('Price', 0)->set('IsNew', 1)->listSelect($dbh);

foreach my $product (@list){
	my $descr = $product->get('Description');
	my $url = $product->get('URL');
	if($descr=~/<span class="span_price"[^>]*>(.*?)<\/span>/){
		my $price = $1;
		$price =~ s/[^\d]//g;
		$product->set('Price', $price);
		$product->update($dbh);
	} else {
		#print "$url\n";
	}
	
	
}

$dbh->commit;
$dbh->disconnect;

exit;


sub echo {
	my $str = shift;
	$str = encode('cp866', $str);
	print "$str\n";
}