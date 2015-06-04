use strict;
use warnings;

use Encode;
use HTML::TreeBuilder::XPath;
use File::Copy;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use ISoft::Exception;

use Category;
use Product;

our $prod_limit = 0;
our $output_html = "html";
our $output_images = "images";

my $dbh = get_dbh();

#test($dbh);
#release_dbh($dbh);
#exit;


my $cat_cache = get_cat_cache($dbh);

my $csv = process_products($dbh, $cat_cache);

open CSV, ">output.csv";
print CSV $csv;
close CSV;

#foreach my $key (keys %$cat_cache){
#	my $value = Encode::encode('cp866', $cat_cache->{$key});
#	if($value=~/;/){
#		print "\n\n**********************************\n\n";
#	}
#	print $value, "\n\n";
#}

release_dbh($dbh);

# ----------------------------

sub test {
	my $dbh = shift;
	
	my $prod_obj = new Product();
	my $prod_list = $prod_obj->selectAll($dbh);
	
	foreach my $prod (@$prod_list){
		
		my $id = $prod->ID;
		
		if(my $descr = $prod->get("Description")){
			
			my $tree = HTML::TreeBuilder::XPath->new;
			$tree->parse_content("<html><head><title>1</title></head><body><span id='contentholder'>$descr</span></body></html");
			my @picnodes = $tree->findnodes( q{//img} );
			if(@picnodes>0){
				
				foreach my $node (@picnodes){
					
					unless($node->attr("isoft:id")){
						my $url = $node->attr("src");
						
						print "$id : $url\n";
					}
					
				}
				
			} else {
				print "$id has no images\n";
			}
			
			
			$tree->delete();
			
		} else {
			print "$id has no description\n";
		}
		
		
		
		
		
		
	}

	
}

sub process_products {
	my ($dbh, $cat_cache) = @_;
	
	if(!-e $output_html){
		mkdir $output_html;
	}
	
	if(!-e $output_images){
		mkdir $output_images;
	}
	
	my $prod_obj = new Product();
	$prod_obj->maxReturn($prod_limit) if $prod_limit;
	my $prod_list = $prod_obj->selectAll($dbh);
	
	my $csv = '';
	my $html_name = "";
	
	foreach my $obj (@$prod_list){
		
		my $str = $obj->Name . ';';
		
		my $cat_id = $obj->get("Category_ID");
		my $prod_id = $obj->ID;
		$str .= $cat_cache->{$cat_id} . ';';
		
		my @pics;
		
		if(my $description = $obj->get('Description')){
			
			my $tree = HTML::TreeBuilder::XPath->new;
			$tree->parse_content("<html><head><title>1</title></head><body><span id='contentholder'>$description</span></body></html");
			my @picnodes = $tree->findnodes( q{//img} );
			foreach my $node (@picnodes){
				my $pm_id = $node->attr('isoft:id');
				$node->attr('isoft:id', undef);
				
				my $pic_obj = $obj->newProductDescriptionPicture;
				$pic_obj->set("ID", $pm_id);
				$pic_obj->select($dbh);
				
				# new name
				my $pic_name = $pic_obj->getIdName();
				push @pics, $pic_name;
				
				# update url
				$node->attr('src', $pic_name);
				
				# copy the picture
				copy($pic_obj->getStoragePath, "$output_images/$pic_name");
				
			}
		
			
			my @cnodes = $tree->findnodes( q{/html/body/span[@id='contentholder']/*} );
			$description = '';
			foreach (@cnodes){
				$description .= $_->as_HTML('<>&', ' ', {});
			}
			$description =~ s/\r|\n|\t/ /g;
			$description =~ s/\s{2,}/ /g;
		
			$tree->delete();
			
			$html_name = "$prod_id.html";
			open XX, ">$output_html/$html_name";
			print XX Encode::encode('cp1251', $description);
			close XX;
			
		}
		
		my $pic_str = join ',', @pics;
		$str .= "$pic_str;$html_name\n";
		
		$csv .= $str;
	}
	
	return Encode::encode('cp1251', $csv);
	
}





sub get_cat_cache {
	my ($dbh) = @_;
	my %cache;
	my $level = 1;
	my $found;
	do {
		my $cat_obj = Category->new();
		$cat_obj->set("Level", $level++);
		my $catlist = $cat_obj->listSelect($dbh);
		$found = @$catlist;
		foreach my $obj (@$catlist){
			my $name = $obj->Name;
			my $id = $obj->ID;
			my $parent_id = $obj->get("Category_ID");
			if($level>2){
				$name = $cache{$parent_id} . '/' . $name;
			}
			$cache{$id} = $name;
		}
	} while ($found);
	return \%cache;
}


