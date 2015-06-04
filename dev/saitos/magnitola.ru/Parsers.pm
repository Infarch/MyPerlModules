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
	@EXPORT = qw( get_categories get_products get_product_info get_product_picture get_next_page );
}

# returns array of hash references
sub get_categories {
	my ($tree, $level) = @_;
	
	# it is possible that we will use different clauses depending on the specified category level
	my ($node_clause, $name_clause, $url_clause);
	
	# uncomment the line below if you want to use the same rules on each category level
	#$level = 1;
	
	if($level==0){
		
		$node_clause = q{//div[@class='vertitem ' and position()<last()]/a}; # <------------ write clause here
		$name_clause = q{.}; # <------------ write clause here
		$url_clause = q{./@href}; # <------------ write clause here
	}
	else{
		$node_clause = q{/html/body/table[2]/tr[3]/td[1]/table[3]/tr/td[2]/table/tr[3]/td/table/tr[1]/td/table/tr/td/table/tr/td[2]/a};
		$name_clause = q{.};
		$url_clause = q{./@href};
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
	my @nodes = $tree->findnodes( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/table/tr[3]/td/table/tr[3]/td/table/tr[position()>1]} ); # <------------ write clause here
	foreach my $node(@nodes){
		my %h;
		$h{Name} = $node->findvalue( q{./td[2]/a/span[@class='productName']} ); # <------------ write clause here
		$h{URL}  = $node->findvalue( q{./td[2]/a/@href} ); # <------------ write clause here
		
		my $gn = $node->findvalue( q{./td[2]/a} );
		my $name = $h{Name};
		
		$gn =~ s/\s*$name$//;
		
		$h{GroupName} = $gn;
		push @list, \%h;
	}
	return \@list;
}

# returns a reference to hash containing product info.
# NOTE : Here should not be information about product pictures! They will be processed by another function
sub get_product_info {
	my $tree = shift;
	my %h;
	
#	my $d = '';
#	my $s = '';
#	my @nodes = $tree->findnodes( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/form/table/tr[4]/td[@class='main']} );
#	if(@nodes==1){
#		
#		my @nlist = $nodes[0]->findnodes( q{./p} );
#		foreach (@nlist){
#			$d .= as_html($_);
#		}
#		
#		my @specs = $nodes[0]->findnodes( q{./table[@class='specs_box']} );
#		$s = as_html($specs[0]) if @specs > 0;
#		
#	}
#	
#	my $xtree = HTML::TreeBuilder::XPath->new;
#	$xtree->parse_content("<html><head><title>1</title></head><body><span id='contentholder'>$d</span></body></html");
#
#	my @picnodes = $xtree->findnodes( q{//img} );
#	foreach my $node (@picnodes){
#		$node->attr('member', '333');
#	}
#
#	my @cnodes = $xtree->findnodes( q{/html/body/span[@id='contentholder']/*} );
#	my $html = '';
#	foreach (@cnodes){
#		$html .= $_->as_HTML('<>&', ' ', {});
#	}
#	$html =~ s/\r|\n|\t/ /g;
#	$html =~ s/\s{2,}/ /g;
	
	my @dnlist = $tree->findnodes( q{//div[@id='DESC']} );
	if (@dnlist==1){
		my $description_node = shift @dnlist;
		my @hdlist = $description_node->findnodes( q{./h2[@class='inside_heading' and position()=1]} );
		$hdlist[0]->delete();
		my @brlist = $description_node->findnodes( q{./br[1]} );
		$brlist[0]->delete();
		
		$h{Description} = as_html($description_node);
	}
	
	
	my $price = $tree->findvalue( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/form/table/tr/td/table/tr/td[2]/span[@class='productSpecialPrice']} );
	unless ($price){
		$price = $tree->findvalue( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/form/table/tr/td/table/tr/td[2]} );
	}
	
	$price =~ s/\D//g;
	$h{Price} = $price || 0;

	my @idnodes = $tree->findnodes( q{//input[@name='products_id']} );
	if(@idnodes>0){
		$h{InternalID} = $idnodes[0]->findvalue( q{./@value} );
	}
	
	return \%h;
}

# returns product picture (main).
sub get_product_picture {
	my $tree = shift;
	my %h;
	my $href = $tree->findvalue( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/form/table/tr[4]/td/table/tr/td/img/@src} );
	$h{URL} = $href;
	
	if($href =~ /\/([^\/]+)$/){
		$h{Name} = $1;
	}
	
	$h{Description} = $tree->findvalue( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/form/table/tr[4]/td/table/tr/td/img/@title} ); # <------------ write clause here
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
		$h{Description} = $node->findvalue( q{./@title} ); # <------------ write clause here
		push @list, \%h;
	}
	return \@list;
}

sub get_next_page {
	my $tree = shift;
	
	my $nxt = '';
	my @nodes = $tree->findnodes( q{/html/body/table[2]/tr[3]/td/table[3]/tr/td[2]/table/tr[3]/td/table/tr[1]/td/table/tr/td[2]/a[last()]} );
	if(@nodes>0){
		my $lst = pop @nodes;
		if(' >>' eq $lst->findvalue( q{.} )){
			$nxt = $lst->findvalue( q{./@href} );
		}
	}
	
	return $nxt;
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
