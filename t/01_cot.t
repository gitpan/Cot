use strict;
use Test::More;

is(system("$^X -wc script/cot"), 0);

done_testing;