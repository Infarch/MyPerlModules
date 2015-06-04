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
use Product;

BEGIN {
	Win32::API->Import(
	  Kernel32 => qq{BOOL CreateDirectoryW(LPWSTR lpPathNameW, VOID *p)}
	);
}

our $PRODUCT_LIMIT = 0;
our $PHOTO_LIMIT = 0;

our $temp = "image.jpg";
our $temp_rar_dir = "extract";
our $temp_rar_file = "tempfile.rar";


if(!-e $temp_rar_dir && !-d $temp_rar_dir){
	mkdir $temp_rar_dir;
}
unlink glob "$temp_rar_dir/*.*";


our $root_dir = Path::Class::Dir->new("z:\\P_FILES");

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
	$root_obj->set("Name", "Panasonic");
	
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
	
	my $name = normal_name( $category_obj->get("Name") );
	my $dir = $parent_dir->subdir($name);
	create_directory($dir);
	
	my @children = $category_obj->getCategories($dbh);
	if(@children > 0){
		# process sub categories
		process_category($_, $dir) foreach @children;
	} else {
		# process products
		my @products = $category_obj->getProducts($dbh, $PRODUCT_LIMIT);
		process_product($_, $dir) foreach @products;
	}
	
}
sub process_product {
	my($product_obj, $parent_dir) = @_;
	
	my $name = normal_name( $product_obj->get("Name") );
	my $dir = $parent_dir->subdir($name);
	create_directory($dir);
	
	# get photos
	my @photos = $product_obj->getProductPictures($dbh, $PHOTO_LIMIT);
	process_photo($_, $dir) foreach @photos;
}

sub process_photo {
	my($photo_obj, $dir) = @_;

	# clean up temporary files
	unlink $temp;
	unlink glob "$temp_rar_dir/*.*";
	
	my $filename = $photo_obj->getOrgName();
	print "$filename\n";
	
	my($name, $ext) = $filename=~/(.+)\.(.+)/;
	
	my $source = $photo_obj->getStoragePath();
	
	# try to extract RAR
	if(lc($ext) eq 'rar'){
		
		copy($source, $temp_rar_file) or die "Cannot copy $source to $temp_rar_file";
		my $cmd = "unrar.bat $temp_rar_dir $temp_rar_file";
		`$cmd`;
		opendir DIR, $temp_rar_dir;
		my @extractedfiles = grep { /\w/ } readdir DIR;
		closedir DIR;
		die "wrong files count" if @extractedfiles != 1;
		my $extractedfile = $extractedfiles[0];
		$source = "$temp_rar_dir/$extractedfile";
		($name, $ext) = $extractedfile=~/(.+)\.(.+)/;
		print "unrar -> $extractedfile\n";
	}
	
	# perform some additional convertation if the file is '.EPS'
	if(lc($ext) eq 'eps'){
		$ext = "jpg";
		my $cmd = "\"$constants{ImageMagick}{CONVERT}\" \"$source\" $temp";
		`$cmd`;
		die "eps2jpg failed" unless -e $temp;
		my $gd = GD::Image->new($temp) or die "GD failed";
		open XX, ">$temp" or die "Cannot open file for writing";
		binmode XX;
		print XX $gd->jpeg();
		close XX;
		$source = $temp;
		$gd = undef;
	}
	
	my $dest = $dir->file("$name.$ext");
	my $fh = create_fh_for_writing($dest);
	binmode $fh;
	open SRC, $source or die "cannot open source file";
	binmode SRC;
	my $buff;
	while(read(SRC, $buff, 4096)){
		print $fh $buff;
	}
	close SRC;
	close $fh;
	
}

sub create_directory {
	my ($dir) = @_;
	my $ucs_path = encode('UCS-2le', "$dir\0");
	CreateDirectoryW($ucs_path, undef) or die "Failed to create directory: '".encode('cp-866', "$dir")."': $^E";
}

sub create_fh_for_writing {
	my ($name) = @_;
	
	my $sym = gensym;

	my $os_fh = CreateFileW(
		encode('UCS-2le', "$name\0"),
		FILE_GENERIC_WRITE,
		FILE_SHARE_READ,
		[],
		CREATE_ALWAYS,
		0,
		[],
	) or die "open error: $^E";
	
	OsFHandleOpen($sym, $os_fh, 'w') or die "OsFHandleOpen failed: $^E";
	
	return $sym;
}
