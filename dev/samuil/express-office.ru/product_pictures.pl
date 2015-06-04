use strict;
use warnings;




# category pictures
opendir DIR, 'files/categorypictures';
my @cats = grep { /^[^\.]/ } readdir DIR;
closedir DIR;

foreach my $cat (@cats){
	
	# thumbnail
	my $th_name = sprintf('expr_cat_%05d', $cat);
	do_convert("files\\categorypictures\\$cat", "-resize", '"100x100>"', "files\\pp_done\\$th_name.jpg");
	
	print "Converted category picture $cat\n";
}

print "Done with category pictures\n";


# product pictures

opendir DIR, 'files/productpictures';
my @files = grep { /^[^\.]/ } readdir DIR;
closedir DIR;

foreach my $file (@files){
	
	# thumbnail
	my $th_name = sprintf('expr_th_%05d', $file);
	do_convert("files\\productpictures\\$file", "-resize", '"150x200>"', "files\\pp_done\\$th_name.jpg");
	
	# info
	my $info_name = sprintf('expr_info_%05d', $file);
	do_convert("files\\productpictures\\$file", "-resize", '"300>"', "files\\pp_done\\$info_name.jpg");
	
	# org - just convert
	my $org_name = sprintf('expr_org_%05d', $file);
	do_convert("files\\productpictures\\$file", "files\\pp_done\\$org_name.jpg");

	print "Converted product picture $file\n";
}

print "Done\n";

exit;

sub do_convert {
	
	unless (system("c:\\work\\im\\convert.exe", @_)==0){
		die "Error!";
	}
	
}