package Parsers;

use strict;
use warnings;

use Error ':try';
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib");
use ISoft::Exception;
use ISoft::Exception::ScriptError;

use base qw(Exporter);
use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );

BEGIN {
	@EXPORT = qw( get_categories get_products get_product_info get_product_picture get_product_additional_pictures get_next_page );
}

# returns array of hash references
sub get_categories {
	my ($tree, $level) = @_;
	
	# it is possible that we will use different clauses depending on the specified category level
	my ($node_clause, $name_clause, $url_clause);
	
	# uncomment the line below if you want to use the same rules on each category level
	#$level = 0;
	
	if($level==0){
		
		$node_clause = q{}; # <------------ write clause here
		$name_clause = q{.}; # <------------ write clause here
		$url_clause = q{./@href}; # <------------ write clause here
	}
#	elsif($level==1){
#		$node_clause = q{};
#		$name_clause = q{.};
#		$url_clause = q{./@href};
#	}
	else {
		throw ISoft::Exception::ScriptError(message=>"Bad category level $level");
	}
	
	my @list;
	my @nodes = $tree->findnodes( $node_clause );
	foreach my $node(@nodes){
		my %h;
		$h{Name} = $node->findvalue( $name_clause );
		$h{URL} = $node->findvalue( $url_clause );
		push @list, \%h;
	}
	return \@list;
}

# returns array of hash references
sub get_products {
	my ($tree) = @_;
	my @list;
	my @nodes = $tree->findnodes( q{} ); # <------------ write clause here
	foreach my $node(@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} ); # <------------ write clause here
		$h{URL} = $node->findvalue( q{./@href} ); # <------------ write clause here
		$h{ShortDescription} = $node->findvalue( q{} ); # <------------ write clause here
		push @list, \%h;
	}
	return \@list;
}

# returns a reference to hash containing product info.
# NOTE : Here should not be information about product pictures! They will be processed by another function
sub get_product_info {
	my $tree = shift;
	my %h;
	
	$h{FullDescription} = $tree->findvalue( q{} ); # <------------ write clause here
	# if the full description should contain html tags then use function "findnode" instead, then get the node's content using "as_html"
	
	$h{InternalID} = $tree->findvalue( q{} ); # <------------ write clause here
	$h{Price} = $tree->findvalue( q{} ); # <------------ write clause here
	$h{Vendor} = $tree->findvalue( q{} ); # <------------ write clause here
	return \%h;
}

# returns product picture (main).
sub get_product_picture {
	my $tree = shift;
	my %h;
	$h{Name} = $tree->findvalue( q{.} ); # <------------ write clause here
	$h{URL} = $tree->findvalue( q{./@src} ); # <------------ write clause here
	$h{ShortDescription} = $tree->findvalue( q{./@title} ); # <------------ write clause here
	return \%h;
}

sub get_product_additional_pictures {
	my $tree = shift;
	my @list;
	my @nodes = $tree->findnodes( q{} ); # <------------ write clause here
	foreach my $node(@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{.} ); # <------------ write clause here
		$h{URL} = $node->findvalue( q{./@href} ); # <------------ write clause here
		$h{ShortDescription} = $node->findvalue( q{./@title} ); # <------------ write clause here
		push @list, \%h;
	}
	return \@list;
}

sub get_next_page {
	my $tree = shift;
	
	return $tree->findvalue( q{} );
	
}



# several auxiliary functions


sub float {
	my ($val) = @_;
	# $val should be string
	$val =~ s/[^\d.]//g;
	return $val ? $val : 0;
}

sub as_html {
	my ($val) = @_;
	# $val should be an instance of HTML::Element
	return $val->as_HTML('<>&');
}




1;
