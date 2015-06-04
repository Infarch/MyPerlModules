use strict;
use warnings;

use threads;

use Thread::Queue;
use Thread::Semaphore;

use Error qw(:try);
use Net::FTP;

use SimpleConfig;
use Utils;


cleanup_state('upload.ready');

my @domain_list = load_lines($constants{General}{UploadList}, not_strict=>1);
if(@domain_list==0){
	print "Upload list is empty, exit\n";
	exit;
}

# look for unique domains
my %unique_domains = map { $_ => 1 } @domain_list;

# first we will upload files through FTP
my $work_sem = Thread::Semaphore->new(0);
my $queue = Thread::Queue->new;

# read content of zip directory
my $zip_storage = $constants{General}{ZipStorage};
my @files = <$zip_storage/*.zip>;

if(@files==0){
	print "Nothing to upload, exit\n";
	exit;
}

# populate the queue
my %uploaded_names;
foreach my $file (@files){
	$queue->enqueue("$file");
	$uploaded_names{ get_file_name($file) } = 1;
}

# start threads
for (my $i = 0; $i<$constants{Uploader}{Threads}; $i++){
	threads->create('worker', $queue, $work_sem)->detach();
}

# waiting for finish
my $working;
do {
	sleep 3;
	{
		lock $$work_sem;
		$working = ($$work_sem > 0) || ($queue->pending() > 0);
	}
} while ($working);


my $path_postfix = exists $constants{Uploader}{RootFolder} ?
	" -d $constants{Uploader}{RootFolder}/" : '';

# read remote host's root directory. look for archives to be extracted
print "Preparing to finalization.\n";
my $script_name = "upload.script";
my $ok = 0;
my $counter = 0;
my $ftp;
my $pause = $constants{Uploader}{PauseAfterError};
do {
	sleep $pause;
	try {
		
		$ftp = prepare_connection();
		my @list = $ftp->ls() or die "Cannot read the remote host\n";
		my @unzip_files_list = grep { /\.zip$/i } @list;
		
		my @cmd_list;
		foreach my $zipfile (@unzip_files_list){
			
			next unless exists $uploaded_names{$zipfile};
			
			push @cmd_list, "call unzip -o $zipfile$path_postfix";
			push @cmd_list, "call unlink $zipfile";
			
		}

		#find $target_dir -type [f or d] | xargs chmod $mode
		#find $target_dir -type [f or d] -exec chmod $mode {} \;

		my $domain_prefix = exists $constants{Uploader}{RootFolder} ?
			"$constants{Uploader}{RootFolder}/" : '';
		
		# change attributes according to domain list
		foreach my $domain (keys %unique_domains){
			push @cmd_list, "call find $domain_prefix$domain -type d -exec chmod 755 {} \\;";
			push @cmd_list, "call find $domain_prefix$domain -type f -exec chmod 644 {} \\;";
		}
		
		# all files were processed
		if(@cmd_list>0){
			
			my @complete_cmd_list = ("open $constants{Uploader}{WinSCP_Session}", "option batch on", "option confirm off", @cmd_list, "exit");
			save_lines($script_name, \@complete_cmd_list);

			# now we should unpack archives using SSH
			sleep $pause;
			print "Starting WinSCP\n";
			my $com = $constants{Uploader}{WinSCP_Com};
			my $redirect = $constants{Uploader}{SuppressEcho} ? ' > null' : '';
			system ($com, "/script=$script_name$redirect");
			if($? != 0){
				die "WinSCP failed";
			}
			
		}

		# all right!
		$ok = 1;
		
	} otherwise {
		# error!
		print "An error happened during finalization. Try again...\n";
		if($constants{Uploader}{UploadTries}){
			if ($counter++ > $constants{Uploader}{UploadTries}){
				die "Fatal error!";
			}
		}
		# we must use 'progressive' pause
		$pause += 5;
	} finally {
		try {
			$ftp->quit;
		} otherwise {
			# an error
		};
	}
	
} while(!$ok);

# remove temporary files
unlink $constants{General}{UploadList};
unlink $script_name;


exit;




# -------------------------------------------------------------------

sub worker {
	my ($queue, $sem) = @_;
	
	my $ftp;
	
	while ( defined( my $file = $queue->dequeue() ) ){
		$sem->up();
		
		print "Uploading $file\n";
		
		try {
			# connect to server we are not connected yet
			$ftp = prepare_connection() unless $ftp;
			$ftp->binary();
			
			upload_file($ftp, $file);
			
		} otherwise {
			
			$queue->enqueue("$file");
			
			print "\nAn error happened during upload: $! \n";
			
			sleep 3;
			
		};

		try {
			$ftp->quit;
		} otherwise {
			# an error
		} finally {
			$ftp = undef;
		};
		
		$sem->down;
		threads->yield();
	}
	
}

sub get_file_name {
	my $file = shift;
	my @parts = split '/', $file;
	return pop @parts;
}

sub upload_file {
	my ($ftp, $file) = @_;
	my $name = get_file_name($file);
	$ftp->put($file, $name) or die "Cannot put file $file: ", $ftp->message;
}

sub prepare_connection {
	my $ftp = Net::FTP->new($constants{Uploader}{FTP_HostName}, Debug => 0)
	  or die "Cannot connect to host: $@";
	$ftp->login($constants{Uploader}{FTP_User}, $constants{Uploader}{FTP_Password})
	  or die "Cannot login : ", $ftp->message;
	return $ftp;
}


