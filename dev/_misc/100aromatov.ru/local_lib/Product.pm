package Product;

use strict;
use warnings;

use lib ("/work/perl_lib");

use ISoft::Exception::ScriptError;

# base class
use base qw(ISoft::ParseEngine::Member::Product);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $self = $class->SUPER::new(@_);

	# create additional columns
	
  $self->addColumn('Details', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  $self->addColumn('ForSale', {
		Type => $ISoft::DB::TYPE_TEXT,
  });

  return $self;
}


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
	
	# extract main picture
	my @nodes = $tree->findnodes( q{//table/tr/td[3]/table/tr/td/table/tr/td[1]/img} );
	if(@nodes>0){
		push @piclist, $self->absoluteUrl($nodes[0]->findvalue('./@src'));
	}
	return \@piclist;
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	
	return [];
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data;
	
	#my @nodes = $tree->findnodes( q{//table/tr/td[3]/table[1]/tr[1]/td[1]/table/tr[1]/td[1]/img/parent::td/parent::tr/parent::table/parent::td} );
	my @nodes = $tree->findnodes( q{//table/tr/td[3]/table[1]/tr[1]/td[1]/table/tr[1]/td[1]/parent::tr/parent::table/parent::td} );
	
	my $node = shift @nodes;
	
	# get the sub-products table
	my $t2 = $node->findnodes( q{./table[@cellpadding='3']} )->get_node(0);
	if(defined $t2){
		$data{ForSale} = $self->asHtml($t2);
		$t2->delete();
	}

	# remove a 'td' with picture
	my $pic_td = $node->findnodes( q{./table/tr/td[1]/img/parent::td} )->get_node(0);
	$pic_td->delete() if defined $pic_td;

	
	# get properties table
	my $prop = $node->findnodes( q{./table/tr/td[1]} )->get_node(0);
	$data{Details} = $self->asHtml($prop) if defined $prop;
	
	# clean up the main node in order to get the pure description
	foreach my $testnode ($node->content_list()){
		if(ref $testnode){
			# this is node
			my $tag = $testnode->tag();
			$testnode->delete();
			last if $tag eq 'table';
		}
	}

	
	# remove the latest block 'do you know'
	foreach my $i ($node->findnodes('.//i')){
		$i->delete();
	}
	
	# get description
	my $descr = '';
	foreach my $testnode ($node->content_list()){
		if(ref $testnode){
			# this is node
			$descr .= $testnode->as_HTML('<>&', '', {});
		} else {
			# this is text
			$descr .= $testnode;
		}
	}
	$descr =~s/<br \/><br \/><br \/>$//;
	$data{Description} = $descr;
	
	return \%data;
}





1;
