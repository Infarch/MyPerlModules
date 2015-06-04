use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use WWW::Mechanize;
use XML::LibXML;
use Encode qw(encode_utf8 decode from_to);

my $mech = WWW::Mechanize->new;

# get main page

$mech->get('http://www.northcyprusinvest.net/properties/');
my $content = pretty_content($mech);

my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
my $root = $dom->createElement('categories');
$dom->setDocumentElement($root);

# get categories
my @category_info;
while ( $content =~ /<a href="(\/properties\/[^\/]+\/)">([^<]+)<\/a>\s<\/li>/g ){
	push @category_info, {
		url => "http://www.northcyprusinvest.net$1",
		name => $2
	};
}

# process each category
foreach my $cdata (@category_info){
	
	my $cat = $root->addNewChild(undef, 'category');
	$cat->setAttribute('url', $cdata->{url});
	$cat->addNewChild(undef, 'name')->appendTextNode($cdata->{name});
	
	my $properties = $cat->addNewChild(undef, 'properties');
	
	# process the category contents
	process_category($properties, $cdata->{url});
	
}

$dom->toFile('result.xml', 1);



#############################################

sub get_next_page {
	my $content = shift;
	my $np = '';
	if ( $content =~ /<div class="navpages">(.+?)<\/div>/ ){
		my $nav = $1;
		if ( $nav =~ /<span>\d+<\/span>\s<a href="([^"]+)">\d+<\/a>/ ) #"
		{
			$np = "http://www.northcyprusinvest.net$1";
			print "Next page : $np\n";
		}
	}
	return $np;
}

sub get_properties {
	my $content = shift;
	
	my @properties;
	
	while ( $content =~ /<div class="photo">(.+?)<\/div>\s<div class="desc">(.+?)<\/div>/g ){
		my $photo_data = $1;
		my $descr_data = $2;
		
		# process short description
		my $url_details = '';
		if ( $descr_data =~ /<a href="(\/properties\/id\d+\/)">/ ) #"
		{
			$url_details = "http://www.northcyprusinvest.net$1";
		}
		
		$descr_data =~ /<h2>(.+?)\s\|\s<span class="price">/;
		my $title = correct_html( $1 );
		
		$descr_data =~ /<span class="usd">(.*?)<\/span>/;
		my $price = '';
		if ( $descr_data =~ /<span class="usd">(.*?)<\/span>/ ) {
			$price = $1;
		} elsif ( $descr_data =~ /<span class="agreement">\s(.+?)\s<\/span>/ ) {
			$price = $1;
		}
		
		$descr_data =~ /<p>(.+)/;
		my $description = correct_html( $1 );
		
		# process thumbnail
		$photo_data =~ /<img src="([^"]+)"/; #"
		my $photo_url = "http://www.northcyprusinvest.net$1";
		
		push @properties, {
			thumbnail => $photo_url,
			url_details => $url_details,
			title => $title,
			price => $price,
			description => $description
		};
	}
	
	return @properties;
}

sub get_property_details {
	my ($url, $node) = @_;

	my $mech = WWW::Mechanize->new(autocheck=>0);
	while(!$mech->get($url)){
		print "Error reading property details\n";
		sleep 1;
	}
	my $content = pretty_content($mech);

	if ( $content =~ /<div class="photos">(.*?)<img src="([^"]+)"/ ) #"
	{
		my $img_name = download_photo("http://www.northcyprusinvest.net$2");
		$node->addNewChild(undef, 'photo')->appendTextNode($img_name);
	}

	if ( $content =~ /<p class="description">(.+?)<\/p>/ ) #"
	{
		$node->addNewChild(undef, 'description')->appendTextNode($1);
	}

	if ( $content =~ /<div class="features">(.+?)<\/div>/ ) #"
	{
		$node->addNewChild(undef, 'features')->appendTextNode($1);
	}
	
}

sub process_category {
	my ($root, $url) = @_;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	
	print "Processing category $url\n";
	
	my $next_page = $url;
	do {
		while ( !$mech->get($next_page) ){
			print "Error: $next_page\n";
			sleep 1;
		}
		my $content = pretty_content( $mech );
		my @properties = get_properties( $content );
		
		# process each the property
		foreach my $property(@properties){
			
			my $pxml = $root->addNewChild(undef, 'property');
			
			$pxml->addNewChild(undef, 'thumbnail')->appendTextNode( download_photo( $property->{thumbnail} ) );
			$pxml->addNewChild(undef, 'title')->appendTextNode( $property->{title} );
			$pxml->addNewChild(undef, 'price')->appendTextNode( $property->{price} );
			$pxml->addNewChild(undef, 'description')->appendTextNode( $property->{description} );
			
			if ( $property->{url_details} ) {
				my $dxml = $pxml->addNewChild(undef, 'details');
				$dxml->setAttribute( 'url', $property->{url_details} );
				get_property_details($property->{url_details}, $dxml);
			}
			
		}
		
		$next_page = get_next_page( $content );
		
	} while ($next_page);
}

sub pretty_content {
	my $mech = shift;
	my $content = $mech->content();
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	return $content;
}

sub correct_html {
	my $str = shift;
	$str =~ s/<[^>]+>//g;
	$str =~ s/^\s+//g;
	$str =~ s/\s+$//g;
	$str =~ s/\s{2,}/ /g;
	return $str;
}

my $photo_counter = 0;

sub download_photo {
	my $url = shift;
	
	my $mech = WWW::Mechanize->new(autocheck=>0);
	while ( !$mech->get($url) ){
		print "Error downloading photo $url\n";
		sleep 1;
	}
	
	my $filename = 'cyprus_' . $photo_counter++;
	
	$url =~ /(\.[^.]+)$/;
	my $ext = $1;
	
	$filename .= $ext;
	
	open (P, ">photo/$filename") or die "Can not create file photo/$filename";
	binmode P;
	print P $mech->content();
	close P;
	
	return $filename;
}




