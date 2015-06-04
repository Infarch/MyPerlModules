use strict;
use warnings;


use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode 'encode';


test();


# ----------------------------

sub test {
	
	my $url = "http://www.100aromatov.ru/fabricator/?id=1"; # the url to be tested
	
	
	my $agent = LWP::UserAgent->new;
	my $response = $agent->get($url);
	
	
	my $content = $response->decoded_content();
	if($content =~ /<img\sborder="0"\shspace="10"\salign="left"\svspace="10"\s
		src="http:\/\/www\.100aromatov\.ru\/showpic\.asp\?type=1&amp;id=\d+"\salt=".*?"><br>(.+?)<br>/x)
	{
		my $descr = $1;
		print encode('cp866', $descr);
	}

	
	
	
#	my $tree = HTML::TreeBuilder::XPath->new;
#	$tree->parse_content($response->decoded_content);

	# my $prop_html = $prop->as_HTML('<>&', '', {});
	# print encode('cp866', $descr);
	
#	my @nodes = $tree->findnodes( q{//table[@cellpadding="15"]/tr/td} );
#	
#	if(@nodes>0){
#		
#		my $node = shift @nodes;
#		my $node_html = $node->as_HTML('<>&', '', {});
#		
#		if($node_html =~ /<img border="0"/)
#		{
#			
#			print "Ok";
#			
#			#my $descr = $1;
#			#print encode('cp866', $descr);
#		}
#		
#		
#		
#		#my $node_html = $node->as_HTML('<>&', '', {});
#		#print encode('cp866', $node_html);
#		
#	}
	
	
}


