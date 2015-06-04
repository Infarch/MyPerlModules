use strict;
use warnings;

use open qw(:std :utf8);

use WWW::Mechanize;


die "The script was already executed and since blocked!";



my @xdata = (
	{
		url => 'http://web.rpo.ru/doclist.aspx?SecID=56',
		file => 'insurance_raw.txt',
		folder => 'insurance'
	},
	{
		url => 'http://web.rpo.ru/doclist.aspx?SecID=59',
		file => 'it-mail_raw.txt',
		folder => 'it-mail'
	}

);

my @data = (
	{
		url => 'http://web.rpo.ru/doclist.aspx?SecID=56',
		file => 'insurance_raw.txt',
		folder => 'insurance'
	}
);


foreach my $dataitem (@data){
	
	# read file, extract ids
	my $file = $dataitem->{file};
	my $url = $dataitem->{url};
	my $folder = $dataitem->{folder};
	
	my $content = '';
	open (XX, $file) or die 'cannot open file';
	while (my $str=<XX>){
		chomp $str;
		$content.=$str;
	}
	close XX;
	
	my $img_counter = 1;
	
	open (NOTES, ">$folder/image-notes.txt") or die $!;
	
	while ( $content =~ /<a href="javascript:renderControl\('(\d+)'\);" class="Item">(.+?)<\/a>/g ){
		my $id = $1;
		my $title = $2;
		
		my $mech = WWW::Mechanize->new();
		
		$mech->get("$url&Cart_CallBack1_Callback_Param=$id");
		
		my $text = $mech->content();
		
		if ( $text =~ /<CallbackContent>\s*<!\[CDATA\[(.+?)\]\]>\s*<\/CallbackContent>/s ){
			
			my $article = "<h1>$title</h1>\n$1";
			
			open XX, ">$folder/$id.txt";
			print XX $article;
			close XX;
			
			# images
			
			my @images = $mech->images();
			print "There are ", scalar @images, " images\n";
			foreach my $image(@images){
				
				my $iurl = $image->url();
				
				# extract extension
				if ( $iurl =~ /\.([^.]+)$/ ){
					my $ext = $1;
					$mech->get($iurl);
					open (IMG, ">$folder/$img_counter.$ext") or die "Cannot create image file\n";
					binmode IMG;
					print IMG $mech->content();
					close IMG;
					
					print NOTES "$iurl => $img_counter.$ext\n";
					
				} else {
					print "Error extracting image name\n";
				}
				
				
				
				$img_counter++;
			}
			
		} else {
			
			print "Cannot extract content\n";
			
		}
		
		
		print "$id\n";
	}
	
	close NOTES;
}

