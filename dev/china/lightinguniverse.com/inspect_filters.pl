use strict;
use warnings;


use Storable qw(freeze thaw);
use Digest::MD5 qw(md5_hex);
use HTTP::Response;
use HTML::TreeBuilder::XPath;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;

use Category;

print "Start inspecting categories\n";

my $dbh = get_dbh();

my @catlist = Category->new->selectAll($dbh);

print scalar @catlist, " categories\n";

my $registry;

foreach my $category (@catlist){
	
	next if $category->get('Level') == 0;
	my $url = $category->get('URL');
	my $name = $category->Name();
	
	print "$name\n";
	
	my $key = md5_hex($url);
	my ($row) = ISoft::DB::do_query($dbh, sql=>"select * from `cache` where `Key`='$key'");
	if(defined $row){
		my $resp = thaw($row->{Content});
		my $content = $resp->content();
		
		#open XX, '>category.htm';
		#print XX $content;
		#close XX;
		
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse_content($content);
		
		#my @nodes = $tree->findnodes( q{//div[@class="narrowBox"]/div[@class="bottomBorder"]/b} );
		my @nodes = $tree->findnodes( q{//div[@class="narrowBox"]/*} );
		my $filtername;
		foreach my $node (@nodes){

			my $tag = $node->tag();
			my $class = $node->attr("class");
			
			next unless $tag && $class;
			
			if($tag eq 'div' && $class eq 'bottomBorder'){
				$filtername = $node->findvalue( q{./b} );
			} elsif ($tag eq 'ul' && $class eq 'narrowWrapperDiv'){
				my @variants = $node->findvalues( q{.//a} );
				foreach my $variant(@variants){
					$registry->{$filtername}->{$variant} = 1;
				}
			}
		}
		
		
		$tree->delete();

	} else {
		print "No cached value\n";
	}
	
	

	
}

open XX, '>filters.txt';
foreach my $key ( sort keys %$registry ){
	print XX "$key\n";

	foreach my $var ( sort keys %{$registry->{$key}} ){
		print XX "\t$var\n";
		
	}
	
}
close XX;


release_dbh($dbh);


