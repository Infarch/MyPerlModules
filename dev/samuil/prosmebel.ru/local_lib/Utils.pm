package Utils;

use strict;
use warnings;

use ISoft::DB;



# inserts a new tag and returns it's ID
sub insert_tag {
	my ($dbh, $tagname, $scripts) = @_;
	
	# insert this tag
	ISoft::DB::do_query($dbh, sql=>"insert into `SC_tags` (`name`) values (?)", values=>[$tagname]);

	# get the tag back
	my ($row) = ISoft::DB::do_query($dbh, sql=>'select * from `SC_tags` where `id`=LAST_INSERT_ID()');
	if(!defined($row) || $row->{name} ne $tagname){
		die "aaa";
	}

	# make script
	push @$scripts, "insert into `SC_tags` (`id`,`name`) values ($row->{id}, '$tagname');";
	
	return $row->{id};
}












1;
