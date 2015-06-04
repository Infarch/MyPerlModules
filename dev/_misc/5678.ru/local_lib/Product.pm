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
  
  my %params  = (
  );
  
  my $self = $class->SUPER::new(%params, @_);

	# create additional columns
	
	 $self->addColumn('Tags', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250,
  });

	 $self->addColumn('EmbedSrc', {
		Type => $ISoft::DB::TYPE_VARCHAR,
		Length => 250,
  });

  return $self;
}

sub extractProductPictures {
	my ($self, $tree) = @_;
	return [];
}

sub extractDescriptionNodes {
	my ($self, $tree) = @_;
	return [];
}

sub extractProductData {
	my ($self, $tree, $description) = @_;
	
	my %data = (Description => $description);
	
	# description
	my @droot = $tree->findnodes( q{//div[@class='description']} );
	my $descr = '';
	foreach my $x ($droot[0]->content_list){
		if(ref $x){
			$descr .= $self->asHtml($x);
		}else{
			$descr .= $x;
		}
	}
	$data{Description} = $descr;
	
	# tags
	my @taglist = $tree->findnodes( q{/html/head/meta[@name='keywords']} );
	$data{Tags} = $taglist[0]->findvalue( q{./@content} );
	
	# src
	my @embedlist = $tree->findnodes( q{//div[@class="videoview"]/embed} );
	$data{EmbedSrc} = $embedlist[0]->findvalue( q{./@src} ) if @embedlist > 0;

	
	return \%data;
}





1;
