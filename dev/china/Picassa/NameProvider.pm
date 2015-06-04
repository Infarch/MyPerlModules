package NameProvider;

use strict;
use warnings;

use base 'Exporter';
use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );

# statuses
our $st_new = 1;
our $st_ready_for_export = 2;
our $st_done = 3;
our $st_failed = 4;

# tables
our $tb_user = 'User';
our $tb_album = 'Album';
our $tb_photo = 'Photo';

# donor
#our $current_user = 'Natalochkamox';


BEGIN {
	
	@EXPORT = qw(
		$st_new $st_ready_for_export $st_done $st_failed
		
		$tb_user $tb_album $tb_photo
	);
	
}



1;
