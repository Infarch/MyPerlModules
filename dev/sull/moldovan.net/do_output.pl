use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use URI;


use ISoft::DBHelper;



# Members
use Product;

my $dbh = get_dbh();

# get products
my $prod = new Product();
my $plist = $prod->selectAll($dbh);

print "Total: ", scalar @$plist, "\n";

my @md;
my @nmd;

my %reg;

foreach my $url (map {$_->get('URL')} @$plist){
	
	
	# without protocol
	if($url!~/^http/){
		$url = qq{http://$url};
	}

	# bug - just one slash: http:/asdc
	if($url=~/^http:\/[^\/](.+)/){
		$url = qq{http://$1};
	}
	
	next if exists $reg{$url};
	$reg{$url} = 1;
	
	my $uri = URI->new($url);
	my $host = $uri->host();
	if($host){
		if( $host =~ /\.md$/i ){
			push @md, $url;
		} else {
			push @nmd, $url;
		}
	} else {
		print $url, "\n";
	}
	
}

print "MD: ", scalar @md, "\n";
print "Not MD: ", scalar @nmd, "\n";

open XX, '>md.txt';
print XX join "\n", @md;
print XX "\n";
close XX;

open XX, '>not_md.txt';
print XX join "\n", @nmd;
print XX "\n";
close XX;




release_dbh($dbh);
exit;



