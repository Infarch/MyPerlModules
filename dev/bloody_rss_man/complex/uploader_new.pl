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


my @work_list = load_lines($constants{General}{UploadList}, not_strict=>1);
if(@work_list==0){
	print "No files for upload, exit\n";
	exit;
}


# first we will upload files through FTP
my $work_sem = Thread::Semaphore->new(0);
my $queue = Thread::Queue->new;


my $path_prefix = exists $constants{Uploader}{RootFolder} ?
	$constants{Uploader}{RootFolder} . '/' : '';


# populate the queue
my %remote_path_hash;
my @do_rm;
while (my $url = shift @work_list){
	my ($domain, $folder) = decode_element($url);
	push @do_rm, $folder;
	my $remote_path = "$path_prefix$domain";
	$remote_path_hash{$folder} = $remote_path;
	
	$queue->enqueue("$folder");
}


# start threads
for (my $i = 0; $i<$constants{Uploader}{Threads}; $i++){
	threads->create('worker', $queue, $work_sem)->detach();
}

my $working;
do {
	sleep 3;
	{
		lock $$work_sem;
		$working = ($$work_sem > 0) || ($queue->pending() > 0);
	}
} while ($working);


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
		my %domain_hash;
		foreach my $zipfile (@unzip_files_list){
			
			$zipfile =~ /(.+?)\.zip$/i;
			my $foldername = $1;
			
			next unless exists $remote_path_hash{$foldername};
			
			# check whether we should create domain folder
			my $path = $remote_path_hash{$foldername};
			unless($domain_hash{ $path }){
				$domain_hash{ $path } = 1;
				push @cmd_list, "call mkdir -p $path";
				push @cmd_list, "chmod 755 $path";
			}
			
			push @cmd_list, "call unzip -o $zipfile -d ".$remote_path_hash{$foldername};
			push @cmd_list, "call unlink $zipfile";
			push @cmd_list, "call chmod 755 $path/$foldername";
			push @cmd_list, "call chmod 644 $path/$foldername/*";
			
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

# remove uploaded files
foreach my $rm_folder(@do_rm){
	unlink <$rm_folder/*.*>;
	rmdir $rm_folder;
}



exit;






# new code !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

sub worker {
	my ($queue, $sem) = @_;
	
	my $ftp;
	
	while ( defined( my $folder = $queue->dequeue() ) ){
		$sem->up();
		
		print "Uploading $folder\n";
		
		try {
			# connect to server we are not connected yet
			$ftp = prepare_connection() unless $ftp;
			$ftp->binary();
			
			upload_file($ftp, $folder);
			
		} otherwise {
			
			$queue->enqueue("$folder");
			
			print "\nAn error happened during upload\n";
			
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

sub upload_file {
	my ($ftp, $name) = @_;

	$ftp->put("$name/$name.zip", "$name.zip") or die "Cannot put file $name.zip: ", $ftp->message;
	
}

sub prepare_connection {
	my $ftp = Net::FTP->new($constants{Uploader}{FTP_HostName}, Debug => 0)
	  or die "Cannot connect to host: $@";
	$ftp->login($constants{Uploader}{FTP_User}, $constants{Uploader}{FTP_Password})
	  or die "Cannot login : ", $ftp->message;
	return $ftp;
}

sub decode_element {
	my $element = shift;
	my $domain = my $folder = '';
	if ($element =~ /^http:\/\/([^\/]+)\/(.*)/){
		$domain = $1;
		$folder = $2;
	} else {
		die "Bad element encountered!";
	}
	return ($domain, $folder);
}
