package Category;

use strict;
use warnings;


use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;
use Manual;

# base class
use base qw(ISoft::ParseEngine::Member::Category);




# change class name for using another class.
# or just remove the function if the standard class is ok for you.
sub newProduct {
	my $self = shift;
	throw ISoft::Exception::ScriptError(message=>"Sure???");
	return ISoft::ParseEngine::Member::Product->new;
}


# for unexpected operations
sub processUnexpected {
	my ($self, $dbh, $tree) = @_;
	
	# extract manuals
	my @nodes = $tree->findnodes( q{.//*[@id='maincol']/div[3]/div/ul/li/a} );
	foreach my $node (@nodes){
		
		my $href = $self->absoluteUrl($node->findvalue( './@href' ));
		my $name = $node->findvalue( '.' );
		$name =~ s/ \([^)]+\)\s*$//;
		
		if($self->debug){
			$self->debugEcho( "$name\n$href\n" );
		} else {
			# insert into DB
			my $manual = Manual->new();
			$manual->set('Category_ID', $self->ID);
			$manual->set('Name', $name);
			$manual->set('URL', $href);
			$manual->insert($dbh);
		}
		
	}

}

sub getManuals {
	my ($self, $dbh, $limit) = @_;
	
	my $obj = Manual->new();
	$obj->set('Category_ID', $self->ID);
	$obj->markDone();
	$obj->maxReturn($limit) if $limit;
	my $listref = $obj->listSelect($dbh);
	
	return wantarray ? @$listref : $listref;
	
}


sub extractNextPage {
	my ($self, $tree) = @_;
	return '';	
}

# extracts the category description
sub extractDescription {
	my ($self, $tree) = @_;
	return '';
}

# extracts sub categories
sub extractSubCategoriesData {
	my ($self, $tree) = @_;
	return [];
}

# extract products
sub extractProducts {
	my ($self, $tree) = @_;
	return [];
}



1;
