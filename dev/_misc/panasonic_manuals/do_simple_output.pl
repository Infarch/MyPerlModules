use strict;
use warnings;


use lib ("/work/perl_lib", "local_lib");

use File::Copy;
use Path::Class;


use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Manual;


our $MANUAL_LIMIT = 1;

our %registry;

our $base_dir = "z:/P_FILES/panasonic_manuals";
our $export_dir = "$base_dir/output";
our $files_list_name = "files.txt";
our @files_list;



our $dbh;

start();

exit;

##########################################

sub start {
	print "Start\n";
	$dbh = get_dbh();
	
	# create the root directory
	if((!-e "$export_dir") || (!-d "$export_dir")){
		print "Init the root directory $export_dir\n";
		mkdir($export_dir);
	}
	
	# get the root category
	my $root_obj = Category->new();
	$root_obj->set('Level', 0);
	$root_obj->select($dbh);
	
	process_category($root_obj, "");
	
	release_dbh($dbh);
	
	open XX, ">$base_dir/$files_list_name";
	foreach my $str (@files_list){
		utf8::encode($str);
		print XX $str, "\n";
	}
	close XX;
}
sub normal_name {
	my $name = shift;
	$name =~ s/^\s+//;
	$name =~ s/\s+$//;
	$name =~ s/[\\\/]/_/g;
	return $name;
}

sub process_category {
	my($category_obj, $path) = @_;
	
	$path .= '\\'.normal_name( $category_obj->get("Name") ) if $category_obj->get("Name");
	
	my @children = $category_obj->getCategories($dbh);
	if(@children > 0){
		# process sub categories
		process_category($_, $path) foreach @children;
	} else {
		# process manuals
		my @manuals = $category_obj->getManuals($dbh, $MANUAL_LIMIT);
		process_manual($_, $path) foreach @manuals;
	}
	
}
sub process_manual {
	my($manual_obj, $path) = @_;
	
	my $org_name = $manual_obj->getOrgName();
	print $org_name, "\n";	
	$path .= '\\'.normal_name($manual_obj->get("Name")).'\\'.$org_name;
	
	my($fname, $ext) = $org_name =~ /(.+)\.(.+)/;
	$org_name = $manual_obj->ID . ".$ext";
	
	copy($manual_obj->getStoragePath(), "$export_dir/$org_name") or die "Copy failed";
	
	push @files_list, "$org_name $path";
}


