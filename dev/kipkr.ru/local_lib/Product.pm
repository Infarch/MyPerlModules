package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);



# returns an instance of a class representing ProductDescriptionPicture.
# uncomment and override the function for using another class.
#sub newProductDescriptionPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new;
#}

# returns an instance of a class representing ProductPicture.
# uncomment and override the function for using another class.
#sub newProductPicture {
#	my $self = shift;
#	return ISoft::ParseEngine::Member::File::ProductPicture->new;
#}

# for unexpected operations
#sub processUnexpected {
#	my ($self, $dbh, $tree) = @_;
#}

# to be overriden in children
#sub descriptionNodeFilter {
#	my ($self, $node) = @_;
#	return 1; # or 0 if you want to skip the node
#}

sub extractProductPictures {
	my ($self, $tree) = @_;
	
	# contains url list, each is the scalar
	my @piclist;
	
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	my @nodes = $tree->findnodes( q{//td[@class="tpl_mainarea"]/*} );
	
	my @tags = qw(h1 hr table hr);
	do {
	
		my $tag = $nodes[0]->tag();
		if($tag eq $tags[0]){
			shift @tags;
			shift @nodes;
		} else {
			@tags = ();
		}
	
	} while (@tags > 0);
	
	
#	
#	foreach my $node (@nodes){
#		my $text = $self->asHtml($node);
#		
#		if($text =~ /img/){
#			print "img\n";
#			
#			print $self->asHtml($node);
#			
#			#my @pictures = $node->findnodes( q{.//img} );
#			
#			
#		}
#		
#	}
	
	
	return \@nodes;
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	return \%data;
}





1;
