use strict;
use warnings;


use lib ("/work/perl_lib", "local_lib");

use File::Copy;
use GD::Image;
use Path::Class;
use Encode 'encode';
use Symbol;
use Win32::API;
use Win32API::File qw(
    CreateFileW CopyFileW OsFHandleOpen
    FILE_GENERIC_READ FILE_GENERIC_WRITE
    OPEN_EXISTING CREATE_ALWAYS FILE_SHARE_READ
);



use ISoft::Conf;
use ISoft::DBHelper;

use Category;
use Manual;

BEGIN {
	Win32::API->Import(
	  Kernel32 => qq{BOOL CreateDirectoryW(LPWSTR lpPathNameW, VOID *p)}
	);
}

our $MANUAL_LIMIT = 0;

our %registry;

our $root_dir = Path::Class::Dir->new("z:\\P_FILES\\panasonic_manuals");

our $dbh;

start();

exit;

##########################################

sub start {
	print "Start\n";
	$dbh = get_dbh();
	
	# create the root directory
	if((!-e "$root_dir") || (!-d "$root_dir")){
		print "Init the root directory $root_dir\n";
		create_directory($root_dir);
	}
	
	# get the root category
	my $root_obj = Category->new();
	$root_obj->set('Level', 0);
	$root_obj->select($dbh);
	$root_obj->set("Name", "output");
	
	process_category($root_obj, $root_dir);
	
	release_dbh($dbh);
}
sub normal_name {
	my $name = shift;
	$name =~ s/^\s+//;
	$name =~ s/\s+$//;
	$name =~ s/[\\\/]/_/g;
	return $name;
}
sub process_category {
	my($category_obj, $parent_dir) = @_;
	
	my $level = $category_obj->get("Level");
	my $dir;
	if($level==1){
		#skip the category
		$dir = $parent_dir;
	} else {
		my $name = normal_name( $category_obj->get("Name") );
		$dir = $parent_dir->subdir($name);
		create_directory($dir);
	}
	
	my @children = $category_obj->getCategories($dbh);
	if(@children > 0){
		# process sub categories
		process_category($_, $dir) foreach @children;
	} else {
		# process manuals
		my @manuals = $category_obj->getManuals($dbh, $MANUAL_LIMIT);
		process_manual($_, $dir) foreach @manuals;
	}
	
}
sub process_manual {
	my($manual_obj, $parent_dir) = @_;
	
	my $org_name = $manual_obj->getOrgName();
	
#	if(length($org_name) > 255){
#		my($fname, $ext) = $org_name =~ /(.+)\.(.+)/;
#		$fname = substr $fname, 0, 250;
#		$org_name = "$fname.$ext";
#	}
	
	print $org_name, "\n";	
	
	# don't create the directory - path limitation!
	
#	# prepare a directory
#	my $name = normal_name( $manual_obj->get("Name") );
#	my $dir = $parent_dir->subdir($name);
#	create_directory($dir);
#	my $dest = $dir->file( $org_name );
	
	my $dest = $parent_dir->file( $org_name );
	
	copyFile( $manual_obj->getStoragePath(), $dest );
	
}

sub create_directory {
	my $dir = "$_[0]";
	my $l = lc $dir;
	unless(exists $registry{$l}){
		#my $ucs_path = encode('UCS-2le', "\\\\?\\$dir\0");
		my $ucs_path = encode('UCS-2le', "$dir\0");
		CreateDirectoryW($ucs_path, undef) or die "Failed to create directory: '".encode('cp-866', "$dir")."': $^E";
		$registry{$l} = 1;
	}
}

sub copyFile {
	my ($source, $dest, $failIfExists) = @_;
	$failIfExists = $failIfExists ? 1 : 0;
	#CopyFileW(encode('UCS-2le', "$source\0"), encode('UCS-2le', "\\\\?\\$dest\0"), $failIfExists) 
	CopyFileW(encode('UCS-2le', "$source\0"), encode('UCS-2le', "$dest\0"), $failIfExists) 
		or die encode('cp-866', "Unable to copy '$source' to '$dest': $^E");
}

