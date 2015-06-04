use strict;
use warnings;

use DB_Member;
use ISoft::Conf;
use ISoft::DB;


# database connection settings
our $db_name = $constants{Database}{DB_Name};
our $db_user = $constants{Database}{DB_User};
our $db_pass = $constants{Database}{DB_Pass};
our $db_host = $constants{Database}{DB_Host};


my %urls = (
	'http://chat.ru/catalog/Lichnye_stranicy/' => 1172,
	'http://chat.ru/catalog/Kompyutery_i_programmy/' => 5759,
	'http://chat.ru/catalog/Kultura_i_iskusstvo/' => 6119,
	'http://chat.ru/catalog/Nauka_i_obrazovanie/' => 5338,
	'http://chat.ru/catalog/Dom_i_semya/' => 3203,
	'http://chat.ru/catalog/Strany_i_puteshestviya/' => 3092,
	'http://chat.ru/catalog/Tovary_i_uslugi/' => 11657,
	'http://chat.ru/catalog/Obwestvo_i_politika/' => 2610,
	'http://chat.ru/catalog/Internet_i_telekommunikacii/' => 13704,
	'http://chat.ru/catalog/Medicina_i_zdorove/' => 2681,
	'http://chat.ru/catalog/Novosti_i_SMI/' => 2832,
	'http://chat.ru/catalog/Otdyx_i_razvlecheniya/' => 8782,
	'http://chat.ru/catalog/Spravki/' => 1659
);

my $dbh = get_dbh();

my $page = 20;

while ( my($url, $count) = each %urls){
	my $start = 1;
	$url =~ s/\/$//;
	
	print "$url\n";
	
	while ($start<$count){
		my $begin = $start;
		my $end = $start+$page-1;
		my $pageurl = "$url-$begin-$end/";
		$start += $page;
		
		my $obj = DB_Member->new;
		$obj->set('URL', $pageurl);
		$obj->set('Type', 1);
		$obj->set('Status', 1);
		$obj->insert($dbh);
		
	}
	$dbh->commit();	
	
}

# ------------------------------------------------------------------------


sub get_dbh {
	return ISoft::DB::get_dbh_mysql($db_name, $db_user, $db_pass, $db_host);
}

