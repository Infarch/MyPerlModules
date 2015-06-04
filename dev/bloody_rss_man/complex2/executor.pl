use strict;
use warnings;

use SimpleConfig;
use Utils;
use List::Util 'shuffle';
use File::Path;

# prepare environment
cleanup_state('upload.ready');
unlink($constants{General}{DomainFolderFile});
unlink($constants{General}{UploadList});
rmtree($constants{General}{ZipStorage});


# once
do_run('generate_df_list.pl');


# for each folder
if( $constants{Parser}{SwitchOff} ){
	print "Parser is blocked\n";
}
do {
	if( $constants{Parser}{SwitchOff} ){
		
		# several operations from parser
		my @dflist = load_lines($constants{General}{DomainFolderFile});
		if (@dflist==0){
			set_state('upload.ready');
		} else {
			my @qlist = load_lines($constants{Parser}{QueriesFile}, not_empty=>1);
			# there should be exactly xx queries according to config file
			my $qcount = $constants{Parser}{Queries};
			my @work_part;
			my @next_part;
			if($qcount > @qlist){
				set_state('upload.ready');
				print "Warning! There are no enough queries!\n";
			} else {
				@work_part = @qlist[0..$qcount-1];
				if ($qcount < @qlist){
					@next_part = @qlist[$qcount..$#qlist];
				}
				# save files
				save_lines($constants{Parser}{QueriesFile}, \@next_part);
				save_lines($constants{General}{KeyWordsFile}, \@work_part);
			}
		}
	} else {

		do_run('parser.pl');
		
		# shuffle
		if (my $count = $constants{General}{ShuffleStrings}){
			my @sfile_list = load_lines($constants{General}{StringCollectionFile}, not_empty=>1);
			foreach (1..$count){
				@sfile_list = shuffle(@sfile_list);
			}
			save_lines($constants{General}{StringCollectionFile}, \@sfile_list);
		}
	}


	do_run('pagemaker.pl');
} while (!check_state('upload.ready'));

# uploading
if($constants{Uploader}{SwitchOff}){
	print "Uploader is blocked\n";
} else {
	do_run('uploader_new.pl');
}





print "\n\nDone.";



sub do_run {
	system (@_);
	if ($? != 0){
		die "Execution of a programm was finished abnormaly\n";
	}
	
}