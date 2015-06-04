use strict;
use warnings;

#no warnings 'utf8';
#use utf8;
#use open qw(:std :utf8);

use SimpleConfig;
use Utils;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Error qw(:try);
use File::Copy;
use File::Path;
use List::Util 'shuffle';
use XML::LibXML;


# first we should check upload state
if (check_state('upload.ready')){
	exit;
}

# define constants

my $index_name = 'index.html';
my $all_name   = 'all.html';
my $page_name  = 'page.html';

my $rss_name  = 'rss.xml';
my $rss_items_limit = 10; # rss file will not contain more items. you can avoid the limitation using zero value (0)
my $rss_lines_from = 1;
my $rss_lines_to = 5; # each rss item will contain a random number of lines between the two values above

my $sfile_log_name = 'log.txt';
my $make_sfile_log = 1;

my $urls_name  = 'urls'; # we don't use any extension here. generated files will have 'txt' type
my $urls_include_all = $constants{PageMaker}{UrlsIncludeAll};
my $urls_include_index = $constants{PageMaker}{UrlsIncludeIndex};


my @kpage_list = load_lines($constants{General}{KeyWordsFile}, not_empty=>1, unique=>1);
if (@kpage_list < 2){
	die "Please use at least two queries!";
}

my @randword_1_list = load_lines('randword.txt', not_empty=>1);
my @randword_2_list = load_lines('randword2.txt', not_empty=>1);
my @dflist          = load_lines($constants{General}{DomainFolderFile});

# sfile collection
my @sfile_list = load_lines($constants{General}{StringCollectionFile}, not_empty=>1);

# a few auxiliary variables
my $sfile_pointer = 0;
my $kpage_pointer = 0;
my $has_rss = 0;
my $rss_parts_count = 0;
my $rss_domain;
my @rss_storage;


my @sf_list;

if (@dflist==0){
	set_state('upload.ready');
	exit;
}
my $df_item = shift @dflist;



# go work!

$rss_domain = $df_item;

# extract domain and folder names
unless ( $df_item =~ /^http:\/\/([^\/]+)\/(.*)/ ){
	die "Bad address $df_item";
}
my $domain_name = $1;
my $folder_name = $2;

print "\n*** Pagemaker generates pages for $df_item ***\n\n";


# prepare target directory
prepare_directory($folder_name);

# copy source directory to target, excluding three files: index, page and all
do_copy ('design', $folder_name);

# process index.htm
process_index("design/$index_name", "$folder_name/$index_name");

# process page.htm
process_page("design/$page_name", $folder_name);

# process all.htm
process_all("design/$all_name", "$folder_name/$all_name");

# rss
if ($has_rss){
	make_rss_file($folder_name);
}

# ulr list
make_urls();

# archive the new directory
my $zip = Archive::Zip->new();
$zip->addTree( "$folder_name/", $folder_name );
# set the best compression level
foreach my $member ($zip->members()){
	
	$member->desiredCompressionMethod( COMPRESSION_DEFLATED );
	$member->desiredCompressionLevel( COMPRESSION_LEVEL_BEST_COMPRESSION );
	
}
unless ( $zip->writeToFileNamed("$folder_name/$folder_name.zip") == AZ_OK ) {
	die 'write zip error';
}

save_lines($constants{General}{DomainFolderFile}, \@dflist);

# add an item to upload list
open (UP, '>>', $constants{General}{UploadList}) or die "Cannot update upload list: $!\n";
print UP "$df_item\n";
close UP;

# save log
save_lines($sfile_log_name, \@sf_list);

print "\n\n";



# ---------------------------------- FUNCTIONS ----------------------------------

sub correct_filename {
	my $str = shift;
	$str =~ s/^\s+//g;
	$str =~ s/\s+$//g;
	$str =~ s/\s+/-/g;
	return $str;
}

sub correct_xml_text {
	my $str = shift;
	
	# wrong characters
	
	$str =~ s/–/-/g;
	$str =~ s/·/-/g;
	$str =~ s/\x85/.../g;
	$str =~ s/°//g;
	$str =~ s/\x93/"/g; #"
	$str =~ s/\x94/"/g; #"
	$str =~ s/\xab/"/g; #"
	$str =~ s/\xbb/"/g; #"
	$str =~ s/\x84/"/g; #"
	$str =~ s/\x88/^/g;
	$str =~ s/\x97/-/g;
	$str =~ s/\x99/(tm)/g;
	$str =~ s/\xae/(r)/g;
	
	return $str;
}

sub make_urls {
	
	my $filename = $urls_name;
	my $number = 1;
	
	# check folder
	my $folder = $constants{PageMaker}{UrlsFolder};
	if($folder){
		$folder =~ s/\\/\//g;
		unless (-e $folder && -d $folder){
			eval { mkpath($folder) };
			if ($@) {
				print "Couldn't create $folder: $@\nUse the current folder instead!\n";
			}
		}
	} else {
		$folder = '.'
	}
	
	$folder .= '/';
	
	# look for the bigger number
	opendir DIR, $folder;
	my @files = readdir DIR;
	closedir DIR;
	
	foreach (@files){
		if ( /^$filename(\d+)\.txt$/ ){
			
			$number = $1+1 if $number<=$1;
			
		}
	}
	
	$filename = "$filename$number.txt";
	
	open(F, ">$folder$filename") or die "Can not create $filename";
	
	if($urls_include_index){
		print F "$rss_domain/$index_name|home\n";
	}

	if($urls_include_all){
		print F "$rss_domain/$all_name|all\n";
	}
	
	foreach my $i ($kpage_pointer .. $#kpage_list){
		my $kp_str = $kpage_list[$i];
		my $kp_file = correct_filename($kp_str);
		print F "$rss_domain/$kp_file.html|$kp_str\n";
	}
	
	close F;
}

sub process_blocks {
	my ($str, $kpage_function_ref) = @_;
	
	# [For_x_y]
	my $done;
	while (!$done){
		if ($str =~ /(\[For_(\d+)_(\d+)\](.*?)\[Endfor\])/i){
			my $block = $1;
			my $begin = $2;
			my $end = $3;
			my $content = $4;
			my $count = get_random($begin, $end);
			$done = 0;
			my $replace = $content x $count;
			substr ($str, index($str, $block), length($block), $replace);
		} else {
			$done = 1;
		}
	}
	
	# process other blocks
	$done = 0;
	while (!$done){
		if ($str =~ /(\[(Kpage|Lindex|Sfile|Slfile|Randnum|Randword|Lpage|All|Rss)[^\]]*\])/i){
			
			my $block = $1;
			my $replace ='???';
			
			# check what kind of block we have found
			
			# [Kpage]
			if ( $block =~ /Kpage/ ){
				$replace = $kpage_function_ref->();
			} elsif ( $block =~ /Lindex/ ) {
				# [Lindex]
				$replace = get_lindex();
			} elsif ( $block =~ /Sfile_(\d+)_(\d+)/ ) {
				# [Sfile_x_y]
				my $begin = $1;
				my $end = $2;
				$replace = get_sfile($begin, $end);
			} elsif ( $block =~ /Slfile_(\d+)_(\d+)_(\d+)_(\d+)/ ) {
				# [Slfile_x_y_z_t]
				my $s1 = $1;
				my $s2 = $2;
				my $sl1 = $3;
				my $sl2 = $4;
				$replace = get_slfile($s1, $s2, $sl1, $sl2);
			} elsif ( $block =~ /Randnum_(\d+)_(\d+)/ ) {
				# [Randnum_x_y]
				my $begin = $1;
				my $end = $2;
				$replace = get_random($begin, $end);
			} elsif ( $block =~ /Randword(\d+|)\]/ ) {
				# [Randword] [Randword2]
				my $source = $1 ? \@randword_2_list : \@randword_1_list;
				$replace = get_randword($source);
			} elsif ( $block =~ /Lpage_(\d+)_(\d+)/ ) {
				# [Lpage_x_y]
				my $begin = $1;
				my $end = $2;
				$replace = get_lpage($begin, $end);
			} elsif ( $block =~ /\[All\]/ ) {
				# [All]
				$replace = get_all();
			} elsif ( $block =~ /\[Rss\]/ ) {
				# [All]
				$replace = get_rss();
				$has_rss = 1;
			}
			
			substr ($str, index($str, $block), length($block), $replace);
		} else {
			$done = 1;
		}
	}
	
	$str =~ s/-!n!-/\n/g;
	return $str;
}

sub get_rss {
	return "$rss_domain/$rss_name";
}

sub process_all {
	my ($src, $dest) = @_;
	open (SRC, $src) or die "Can not open $src";
	my $str = '';
	while (<SRC>) {
		chomp;
		$str .= "$_-!n!-";
	}
	close SRC;
	
	$str = process_blocks($str, \&get_all_kpage);
	
	open (DEST, ">$dest") or die "Can not open $dest";
	print DEST $str;
	print "Processed $all_name\n";
	close DEST;
}

sub get_all {
	my $str = '';
	foreach my $i ($kpage_pointer .. $#kpage_list){
		my $kp = $kpage_list[$i];
		$str .= make_link($kp);
		$str .= '<br />-!n!-';
	}
	return $str;
}

sub process_page {
	my ($src, $dest) = @_;

	# load the page file into memory in order to speed up process
	my $page_str = '';
	open (PAGE, $src) or die "Can not open $src";
	while (<PAGE>) {
		chomp;
		$page_str .= "$_-!n!-";
	}
	close PAGE;
	
	# loop through kpage_list, generate pages
	
	foreach my $i ($kpage_pointer .. $#kpage_list){
		my $kpage_item = $kpage_list[$i];
		make_a_page($dest, $kpage_item, $page_str);
	}
	print "Created Kpages\n";
}

sub make_a_page {
	my ($target_dir, $kp_str, $pstr) = @_;
	
	my $gpk = sub {
		return ucfirst $kp_str;
	};
	
	# determine file name
	my $kp_filename = correct_filename($kp_str);
	$kp_filename .= '.html';

	# prepare rss data
	insert_rss_part($kp_str, "$rss_domain/$kp_filename");
	
	my $str = process_blocks($pstr, $gpk);
	
	# open target file
	open (TARGET, ">$target_dir/$kp_filename") or die "Can not open $target_dir/$kp_filename";
	print TARGET $str;
	close TARGET;
}

sub process_index {
	my ($src, $dest) = @_;
	open (SRC, $src) or die "Can not open $src";
	my $str = '';
	while (<SRC>) {
		chomp;
		$str .= "$_-!n!-";
	}
	close SRC;
	
	# process blocks within the string
	$str = process_blocks($str, \&get_index_kpage);

	
	open (DEST, ">$dest") or die "Can not open $dest";
	print DEST $str;
	print "Processed $index_name\n";	
}

sub insert_rss_part {
	my ($title, $link) = @_;
	
	if ( $rss_items_limit > 0 && $rss_parts_count == $rss_items_limit ){
		return;
	}
	
	$rss_parts_count++;
	
	my $text = '';
	my $spos = $sfile_pointer;
	
	my $count = get_random($rss_lines_from, $rss_lines_to);
	
	foreach (1 .. $count) {
		$text .= $sfile_list[$spos++];
		$text .= "\n";
		if ($spos==@sfile_list){
			$spos = 0;
		}
	}

	push @rss_storage, {
		title => $title,
		description => $text,
		link => $link
	};	
	
}

sub make_rss_file {
	my $td = shift;
	
	# make xml
	
	#my $dom = XML::LibXML::Document->new('1.0', 'ASCII');
	my $dom = XML::LibXML::Document->new('1.0');
	my $root = $dom->createElement('rss');
	$dom->setDocumentElement($root);
	$root->setAttribute('version', '2.0');
	
	my $channel = $root->addNewChild(undef, 'channel');
	$channel->addNewChild(undef, 'title')->appendTextNode( correct_xml_text( get_index_kpage() ) );
	$channel->addNewChild(undef, 'description')->appendTextNode( correct_xml_text( 'myfirstdescription for '.get_index_kpage() ) );
	$channel->addNewChild(undef, 'link')->appendTextNode( "$rss_domain/$index_name" );

	# populate
	foreach my $item (@rss_storage){
		try {
			my $ritem = $channel->addNewChild(undef, 'item');
			$ritem->addNewChild(undef, 'title')->appendTextNode( correct_xml_text( $item->{title} ) );
			$ritem->addNewChild(undef, 'description')->appendTextNode( correct_xml_text( $item->{description} ) );
			$ritem->addNewChild(undef, 'link')->appendTextNode( $item->{link} );
		} otherwise {
			print "An error happened: $@\nSkipping the RSS item\n";
		};
	}

	try {
		$dom->toFile("$td/$rss_name", 1);
	} otherwise {
		print "Please have a look at rss file!\n";
	};

	print "Created Rss $rss_name\n";
}

sub get_randword {
	my ($source) = @_;
	my $wordpos = int( rand(scalar @$source) );
	return $source->[$wordpos];
}

sub get_lpage {
	my ($begin, $end) = @_;
	my $count = get_random($begin, $end);
	my @temp;
	foreach (1..$count){
		my $kpos = int( rand( $#kpage_list + 1 - $kpage_pointer ) ) + $kpage_pointer;
		my $kp = $kpage_list[ $kpos ];
		push @temp, make_link($kp).'<br/>';
	}
	return join '-!n!-', @temp;
}

sub get_sfile_part {
	my ($begin, $end) = @_;
	my $random = get_random($begin, $end);
	my @temp;
	my $counter = 0;
	while ($counter<$random) {
		my $sf_str = $sfile_list[$sfile_pointer++];
		push (@temp, $sf_str);
		# log
		if ($make_sfile_log){
			push @sf_list, $sf_str;
		}
		$counter++;
		if ($sfile_pointer==@sfile_list){
			$sfile_pointer = 0;
		}
	}
	return \@temp;
}

sub get_slfile {
	my ($s1, $s2, $sl1, $sl2) = @_;
	
	# get strings
	my $strings_ref = get_sfile_part($s1, $s2);
	
	# make a single string from the string collection using a special separator token
	my $string = join ' -!n!-', @$strings_ref;
	
	# get and format links
	my @links;
	foreach (1 .. get_random($sl1, $sl2)){
		my $kpos = int( rand( $#kpage_list + 1 - $kpage_pointer ) ) + $kpage_pointer;
		my $kp = $kpage_list[ $kpos ];
		push @links, make_link($kp);
	}
	
	# get positions of space characters
	my @positions;
	while ( $string =~ /\s/g  ) {
		push @positions, pos($string);
	}
	
	# it is possible that there are no enought positions. in this case we just append a few space characters
	my $pcount = @positions;
	my $lcount = @links;
	while ($pcount < $lcount) {
		$string .= ' ';
		push @positions, length($string)-1;
		$pcount++;
	}
	
	# shuffle positions
	my @shuffled = shuffle(@positions);
	
	# take the first x positions and then sort them ascending
	my @temp = sort {$a <=> $b} @shuffled[0 .. $#links];
	
	# now we have positions, let's insert links
	my $offset = 0;
	foreach my $i(0 .. $#links){
		my $lnk = ' ' . $links[$i] . ' ';
		substr($string, $temp[$i]-1+$offset, 1, $lnk);
		# we must make a correction after insert
		$offset += length $lnk;
		$offset--;
	}

	return $string;
}

sub get_sfile {
	my ($begin, $end) = @_;
	my $tmp_ref = get_sfile_part($begin, $end);
	return join ' -!n!-', @$tmp_ref;
}

sub get_lindex {
	return "<a href=\"./$index_name\">Home</a>";
}

sub get_index_kpage {
	$kpage_pointer = 1;
	return ucfirst $kpage_list[0];
}

sub get_all_kpage {
	return ucfirst $kpage_list[ $#kpage_list ];
}

sub do_copy {
	my ($src, $dest) = @_;
	opendir (SRC, $src) or die "Can not open $src";
	my @dirlist = grep { /^[^.]/ } readdir SRC;
	closedir SRC;
	foreach (@dirlist){
		
		# we dont use name constants here. first we need to check the functionality in whole
		
		next if /^(page|index|all)\.html/i;
		copy("$src/$_", "$dest/$_") or die "Cannot copy $src/$_ to $dest/$_";
	}
	print "Copied files to target directory\n";
}

#sub load_library {
#	my ($filename, $arr_ref) = @_;
#	open (SRC, $filename) or die "Cannot load $filename";
#	while (<SRC>){
#		chomp;
#		if ($_ && /\S/){
#			push @$arr_ref, $_;
#		}
#	}
#	close SRC;
#	print "Loaded $filename (", scalar @$arr_ref, " records)\n";
#}

sub get_random {
	return int( rand($_[1] - $_[0]) + $_[0] );
}

sub make_link {
	my ($text, $name) = @_;
	$name = defined $name ? $name : $text;
	$text = correct_filename($text);
	return "<a href=\"./$text.html\" title=\"$name\">$name</a>";
}

sub prepare_directory {
	my ($folder_name) = @_;
	
	# check existence of the folder
	if ( -e $folder_name && -d $folder_name){
		# clean up
		opendir DIR, $folder_name;
		my @files = grep { /[^.]/ } readdir DIR;
		closedir DIR;
		foreach my $file (@files){
			unlink "$folder_name/$file";
		}
	} else {
		# create
		mkdir($folder_name) or die $!;
	}
	
}

