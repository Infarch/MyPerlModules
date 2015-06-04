use strict;
use warnings;


use GD::Image;

#my $file = "ill-jet-pink.eps";
my $file = "image.jpg";


my $gd = GD::Image->new($file);

open XX, '>converted.jpg';
binmode XX;
print XX $gd->jpeg();
close XX;
