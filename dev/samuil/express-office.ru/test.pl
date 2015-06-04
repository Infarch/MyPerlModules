use strict;
use warnings;

use Carp;
use Error ':try';
use Encode qw/encode decode/;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;

use lib ("/work/perl_lib");
use ISoft::DB;
use ISoft::Exception;
use ISoft::Exception::ScriptError;


use Category;
use Product;
use CategoryPicture;
use ProductDescriptionPicture;
use ProductPicture;

use ISoft::ParseEngine::ThreadProcessor;

test();

# -----------------------------------------------------------------------

sub test {
	
	my $tp = new ISoft::ParseEngine::ThreadProcessor(dbname=>'express');
	
	my $dbh = $tp->getDbh();

	my @objlist = (
		Category->new,
		Product->new,
		CategoryPicture->new,
		ProductPicture->new,
		ProductDescriptionPicture->new,
		Price->new
	);
	
	# prepare environment
	
	foreach my $obj (@objlist){
		$obj->prepareEnvironment($dbh);
		$dbh->commit();
	}
	
	# make root
	my $root = Category->new;
	$root->set('URL', 'http://www.express-office.ru/catalog/');
	$root->set('Level', 0);
	unless($root->checkExistence($dbh)){
		$root->insert($dbh);
		$dbh->commit();
	}
	$dbh->rollback();
	$dbh->disconnect();
	
	foreach my $workobj(@objlist){
		
		my $tbname = $workobj->tablename();
		
		my $work = 1;
		my $stop;
		do {
			
			# get a new handler in order to avoid a strange mistake
			my $dbhx = $tp->getDbh();
			my @worklist = $workobj->getWorkList($dbhx, 500);
			$dbhx->rollback();
			$dbhx->disconnect();
			
			if(@worklist>0){
				print "Enqueue ", scalar @worklist, " items from $tbname\n";
				
				$tp->enqueueMember(@worklist);
				$tp->start(1);
				$stop = $tp->stop();
			} else {
				$work = 0;
			}
		} while ( $work && !$stop );
		last if $stop;
	}
	
	if($tp->stop()){
		print "Thread processor stopped!!!\n\n";
	} else {
		print "Done\n\n";
	}

	my $fdbh = $tp->getDbh();
	foreach my $obj (@objlist){
		my $tbname = $obj->tablename();
		my $failed = $obj->getFailedCount($fdbh);
		print "$tbname: $failed failed records\n";
	}
	$fdbh->rollback();
	$fdbh->disconnect();

}





1;