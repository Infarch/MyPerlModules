use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use File::Copy;

use ISoft::Conf;
use ISoft::DBHelper;

use Product;

my $tempdir = "extract";
my $tempfile = "tempfile.rar";

if(!-e $tempdir && !-d $tempdir){
	mkdir $tempdir;
}

my $dbh = get_dbh;

my @list = ProductPicture->new()->newProductPicture()->selectAll($dbh);

foreach my $obj (@list){
	
	my $filename = $obj->getOrgName();
	my($name, $ext) = $filename=~/(.+)\.(.+)/;

	next unless lc($ext) eq 'rar';
	
	print $filename, "\n";
	
	my $source = $obj->getStoragePath();
	copy($source, "tempfile.rar") or die "Cannot copy $source";
	my $cmd = "unrar.bat $tempdir $tempfile";
	`$cmd`;
	
	opendir DIR, $tempdir;
	my @files = grep { /\w/ } readdir DIR;
	closedir DIR;
	
	print "-- $_\n" foreach @files;
	die "wrong files count" if @files != 1;
	
	my $file = $files[0];
	
	$obj->set('FileName', $file);
	
	
	unlink glob "$tempdir/*.*";
}

release_dbh($dbh);
