use strict;
use warnings;

use open qw(:std :utf8);

use WWW::Mechanize;
use XML::LibXML;



my $dataname = 'information';

# load url list
open LL, "$dataname.txt";
my @list;
while(<LL>){
	chomp;
	push @list, $_;
}
close LL;

my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
my $root = $dom->createElement('products');
$dom->setDocumentElement($root);

foreach my $url (@list){
	print "$url\n";
	
	my $data = get_page_content($url);
	my $info = get_product_info($data);
	
	my $img_name = download_image($info->{image_url});
	$info->{image_name} = $img_name if $img_name;

	append_xml($root, $info);	
}

$dom->toFile("$dataname.xml", 1);











sub append_xml {
	my ($root, $data) = @_;
	
	my $node = $root->addNewChild(undef, 'product');
	
	$node->addNewChild(undef, 'name')->appendText($data->{name});
	$node->addNewChild(undef, 'vendor')->appendText($data->{vendor});
	$node->addNewChild(undef, 'id')->appendText($data->{id});
	$node->addNewChild(undef, 'inblock')->appendText($data->{inblock});
	$node->addNewChild(undef, 'image_name')->appendText($data->{image_name}) if defined $data->{image_name};
	
	if(exists $data->{details}){
		$node = $node->addNewChild(undef, 'descriptionlist');
		foreach my $ditem (@{$data->{details}}){
			my $tmp_node = $node->addNewChild(undef, 'descriptionitem');
			$tmp_node->setAttribute('name', $ditem->{name});
			$tmp_node->appendText($ditem->{value});
		}
	}
	
}

sub download_image {
	my $url = shift;
	
	my $mech = WWW::Mechanize->new(autocheck=>0);
	return undef unless $mech->get($url);
	my $idata = $mech->content;
		
	$url =~ /\/([^\/]+)$/;
	
	my $name = $1;
	
	open (IMG, ">product_images/$name") or die "Cannot create file product_images/$name";
	binmode IMG;
	print IMG $idata;
	close IMG;
	
	return $name;
}

sub get_product_info {
	my $content = shift;
	
	unless( $content =~ /<table Class = "Prod">(.+?)<\/table>/ ){
		die "There is no product details table!";
	}
	
	my %pdata;
	
	my $details = $1;
	my @details_names = qw ( name vendor id 0 inblock );
	my $i = 0;
	
	while ( $details =~ /<tr[^>]*>\s<td[^>]*>[^<]*<\/td>\s<td[^>]*>\[*(.*?)\]*<\/td>\s<\/tr>/g ){
		my $dname = $details_names[$i++];
		next unless $dname;
		$pdata{$dname} = $1;
	}
	
	my $id = $pdata{id} or die "No product id";
	
	my $img_url = 'http://web.rpo.ru/ProdPics/' . sprintf("%04d", $id) . '.gif';
	$pdata{image_url} = $img_url;
	
	if( $content =~ /<table class="ProdNorm" cellspacing="2" cellpadding="2" border="0" id="ProductDetails1_ProdData">(.+?)<\/table>/ ){
		$details = $1;
		my @dlist;
		while ( $details =~ /<tr[^>]*>\s<td[^>]*>(.*?)<\/td>\s*<td[^>]*>(.*?)<\/td>\s*<\/tr>/g ){
			push @dlist, {
				name => $1,
				value => $2
			};
		}
		$pdata{details} = \@dlist;
	} else {
		print "There is no product description table!\n";
	}
	
	
	
	return \%pdata;
}

sub get_page_content {
	my $url = shift;
	return pretty_content( safe_get($url) );
}

# ##############################################################################

sub pretty_content {
	my $content = shift;
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	return $content;
}

sub safe_get {
	my $url = shift;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	while (!$mech->get($url)){
		print "Error getting $url\n";
		sleep 1;
	}
	return $mech->content();
}

