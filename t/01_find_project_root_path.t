#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use Path::Tiny;
use Test::More::Autodoc::Path;

use Test::More;

my $got      = Test::More::Autodoc::Path->find_project_root_path->absolute;
my $expected = path($FindBin::Bin)->parent->absolute;

is $got, $expected, 'find project root';

done_testing;
