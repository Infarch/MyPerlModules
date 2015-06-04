use strict;
use warnings;

use Error ':try';
use YPage;
use SimpleConfig;
use Utils;

our $source  = $constants{General}{SourceFile};
our $dest    = $constants{General}{OutputFile};
our $use_www = $constants{General}{UseWWW};


# read the file
my @sitelist_raw;
my @sitelist;
Utils::load_lines($source, \@sitelist_raw);
foreach my $line (@sitelist_raw){
	chomp $line;
	$line=~s/^http(s|):\/\///i;
	$line=~s/\/$//;
	if ( $line=~/\S/ ){
		push @sitelist, $line;
		if($use_www){
			if($line =~ /^www\.(.*)/i){
				push @sitelist, $1
			} else {
				push @sitelist, "www.$line";
			}
		}
	}
}

print scalar @sitelist, " sites to be processed\n";

# instantiate the service object
my $yp = YPage->new;
$yp->init();

my %sitehash;
my @collector;
foreach my $site (@sitelist){
	next if $sitehash{$site};
	$sitehash{$site} = 1;
	try {
		push @collector, $yp->process($site);
		print "$site - success\n";
	} otherwise {
		print "$site FAILED : $@\n";
	};
}

print "Creating output file\n";

Utils::save_lines($dest, \@collector);

print "Done\n";
