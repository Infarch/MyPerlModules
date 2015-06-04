use strict;
use warnings;

use SimpleConfig;
use Utils;
use List::Util 'shuffle';

# prepare environment
cleanup_state('upload.ready');
unlink($constants{General}{DomainFolderFile});
unlink($constants{General}{UploadList});


# once
do_run('generate_df_list.pl');

# for each folder
do {
	do_run('parser.pl');

	# shuffle
	if (my $count = $constants{General}{ShuffleStrings}){
		my @sfile_list = load_lines($constants{General}{StringCollectionFile}, not_empty=>1);
		foreach (1..$count){
			@sfile_list = shuffle(@sfile_list);
		}
		save_lines($constants{General}{StringCollectionFile}, \@sfile_list);
	}

	do_run('pagemaker.pl');
} while (!check_state('upload.ready'));

# uploading
do_run('uploader_new.pl');




print "\n\nDone.";



sub do_run {
	system (@_);
	if ($? != 0){
		die "Execution of a programm was finished abnormaly\n";
	}
	
}