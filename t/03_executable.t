use strict;
use Test::More;
use File::stat;

ok(stat('script/cot')->mode & 0755);

done_testing;