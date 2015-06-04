use strict;
use warnings;

use WWW::Mechanize;

open DST, '>corrected.xml';

open XML, 'backup.xml';
while( my $str = <XML> ){
	
	# get url
	$str =~ /<url>(.*?)<url>/;
	my $url = $1;
	

	# check image
	
	if ( $str =~ /<image><\/image>/ ){
		my $img = '';
		print "$url ";
		# get the page content
		my $content = get_content($url);
		$content =~ s/\r|\n/ /g;
		# get image link
		if ( $content =~ /<td align="left" ><img src="([^"]+)"><\/td>/ )#"
		{
			$img = $1;
			# download the image
			my $img_content = get_content("http://www.trade31.com/$img");
			my @picnames = split '/', $img;
			$img = pop @picnames;
			# save to disk
			open IMG, ">img_corr/$img";
			binmode IMG;
			print IMG $img_content;
			close IMG;
			# correct xml string
			$img = "<image>$img</image>";
			$str =~ s/<image><\/image>/$img/;
			print " ok\n";
		} else {
			print " no image\n";
		}

	}
	
	print DST $str;
	
}
close XML;
close DST;



sub get_content {
	my $url = shift;
	my $mech = WWW::Mechanize->new(autocheck=>0);
	
	my $ok;
	do {
		$ok = $mech->get($url);
	} while (!$ok);
	
	return $mech->content;
}

