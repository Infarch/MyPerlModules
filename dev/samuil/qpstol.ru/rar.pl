use strict;
use warnings;

use utf8;

use Data::Dumper;
use Encode qw/encode decode/;
use Error ':try';
use File::Path;
use File::Copy;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;



use Category;
use Product;
use ProductPicture;
use AssemblyManual;



my $dbh = get_dbh();

# get products where description contains .rar parts
my $obj = Product->new;
$obj->where("description like '%.rar%'");
my @prodlist = $obj->listSelect($dbh);

print scalar @prodlist, " products should be corrected\n";

foreach my $product( @prodlist ){
	
	my %man_registry;
	
	my $product_id = $product->ID;
	my $description = $product->get("Description");
	
	my $content = "<html><body>$description</body></html>";

	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	# look for manual
	my @manuals = grep { $_->attr('href')=~/\.rar$/i } $tree->findnodes( q{.//a} );
	foreach my $manual (@manuals){
		my $url = $manual->attr('href');
		$url = $product->absoluteUrl($url);
		next if exists $man_registry{$url};
		$man_registry{$url} = 1;
		
		my $manual_obj = AssemblyManual->new;
		$manual_obj->set('Product_ID', $product_id);
		$manual_obj->set('URL', $url);
		$manual_obj->select($dbh);
		
		$manual->attr('isoft:id', $manual_obj->ID);
	}

	my $div = ( $tree->findnodes('/html/body/div') )[0];
	$content = $product->asHtml($div);
	
	$product->set("Description", $content);
	$product->update($dbh);
	
	$tree->delete();
	
}

$dbh->commit();

release_dbh($dbh);
