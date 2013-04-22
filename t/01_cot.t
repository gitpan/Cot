use strict;
use Test::More;

is(system('perl -wc script/cot'), 0);

done_testing;