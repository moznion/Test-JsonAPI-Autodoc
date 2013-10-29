#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::More::Autodoc;

describe "not specify 'autodoc'" => sub {
    ok 1;
};

describe 'enable', "specify 'autodoc'" => sub {
    ok 1;
};

done_testing;
