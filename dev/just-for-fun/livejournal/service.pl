use strict;
use warnings;

use lib ("/work/perl_lib");
use ISoft::Conf;
use ISoft::DB;


my $commands = {
	cleanup => {
		description => "Removes ALL items from the $constants{Database}{DB_Name}.Member table",
		danger => 1,
		handler => \&cleanup,
	},
	test => {
		description => 'A usual function',
		handler => \&test,
		args => [1,2,3]
	},
	test1 => {
		description => 'A danger function',
		danger => 1,
		handler => \&test1
	},
};


# read the command line
my $option = $ARGV[0];
if ($option && (my $cmd = $commands->{$option})){
	
	if($cmd->{danger}){
		# do additional confirmation
		my $yes = 'YES';
		print "You have selected a DANGER function.\nPlease confirm your intention by typping $yes... ";
		my $line = <STDIN>;
		chomp $line;
		if($line ne $yes){
			print "It seems that you don't want to execute this operation :)\n";
		}
	}
	
	
	
	
	# execute
	my @args;
	if (defined $cmd->{args}){
		@args = @{ $cmd->{args} };
	}
	$cmd->{handler}->(@args);
	
} else {
	print "Please apecify a command to be executed. Format: service.pl command\n\n";
	print "Supported commands:\n";
	
	foreach my $key (keys %$commands){
		print "$key : $commands->{$key}->{description}\n";
	}
	
}













# ---------------------- Handlers ----------------------

sub test {
	my @args = @_;
	print "Called Test @args\n";
}

sub test1 {
	print "Called Test 1\n";
}

# clean up database
sub cleanup {
	my $dbh = get_dbh();
	
	my $tname = 'Member';
	
	# clean up parents
	my $sql = "update $tname set Member_ID=null";
	ISoft::DB::do_query($dbh, sql=>$sql);
	
	# remove all members
	$sql = "delete from $tname";
	ISoft::DB::do_query($dbh, sql=>$sql);
	
	$dbh->commit();
	$dbh->disconnect();
}

# ---------------------- Auxiliary functions ----------------------

sub get_dbh {
	return ISoft::DB::get_dbh_mysql($constants{Database}{DB_Name}, $constants{Database}{DB_User}, $constants{Database}{DB_Pass});
}
