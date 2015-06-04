use strict;
use warnings;

use SimpleConfig;
use Utils;

my $folder = 'xy+z';

$folder =~ s/\+/ /g;

print $folder;
