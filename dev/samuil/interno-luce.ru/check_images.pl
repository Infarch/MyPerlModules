use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;

print "Hello! Let's check files in ".$constants{Files}{Root}, "\n\n";

my $source = $constants{Files}{Root} . '/' . $constants{Files}{Products};
opendir DIR, $source;
my @files = grep { -f "$source/$_" && /^\d+\.jpg$/} readdir DIR;
closedir DIR;

print scalar @files;

