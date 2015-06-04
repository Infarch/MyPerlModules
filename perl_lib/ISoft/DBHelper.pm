package ISoft::DBHelper;


use strict;
use warnings;

use ISoft::Conf;
use ISoft::DB;

use base qw(Exporter);
use vars qw( @EXPORT );


BEGIN {
	@EXPORT = qw( get_dbh release_dbh );
}

# -------------------------------------------------------

sub release_dbh {
	my $dbh = shift;
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




1;
