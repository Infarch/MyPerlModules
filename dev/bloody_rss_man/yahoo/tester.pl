use strict;
use warnings;

use YPage;

my $yp = YPage->new;
$yp->init();
$yp->process('free-lance.ru');
$yp->process('apache.org');
