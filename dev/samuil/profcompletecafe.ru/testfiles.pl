use strict;
use warnings;


# parse data



use Error ':try';
use LWP::UserAgent;


use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;

# Members
use Product;
use Price;

use ISoft::ParseEngine::Member::File::ProductPicture;



start();


# ----------------------------

sub start {

	# get database handler
	my $dbh = get_dbh();
	
	# get products
	
	my @list = ISoft::ParseEngine::Member::File::ProductPicture->new()->selectAll($dbh);
	
	foreach my $pic (@list){
		
		print $pic->getMD5Name(), "\n";
		
	}
	
	$dbh->rollback();
	$dbh->disconnect();
		
}


sub get_dbh {
	return ISoft::DB::get_dbh_mysql(
		$constants{Database}{DB_Name},
		$constants{Database}{DB_User},
		$constants{Database}{DB_Password},
		$constants{Database}{DB_Host}
	);
}

