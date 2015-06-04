use strict;
use warnings;

use utf8;

use Error ':try';
use Encode qw/encode decode/;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;

use lib ("/work/perl_lib");
use ISoft::DB;
use ISoft::Exception;
use ISoft::Exception::ScriptError;


use Category;
use Product;
use CategoryPicture;
use ProductDescriptionPicture;
use ProductPicture;

use ISoft::ParseEngine::ThreadProcessor;

test();

# -----------------------------------------------------------------------

sub test {
	
	my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
	my $dbh = $tp->getDbh();

	my $prod = Product->new;
	$prod->where(' Description like \'%бренд%\'');
	$prod->listSelect($dbh);
	
	my $lref = $prod->listSelect($dbh);
	


	return;
	
	my $obj = Product->new;
	$obj->set('URL', 'http://www.express-office.ru/catalog/metall-furniture/racks/metal-racks/49170/');
	$obj->set('ID', 666);
	$obj->set('IsNew', 1);

	my $agent = LWP::UserAgent->new;
	my $r = $obj->getRequest();
	my $resp = $agent->request($r);
	try {
		$obj->processResponse(undef, $resp, 1);
	} otherwise {
		print $@->trace();
	};

	#$dbh->rollback();
	#$dbh->disconnect();
	

}

