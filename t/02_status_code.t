#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::More::Autodoc;

# TODO BAD TESTS!!!!!!!!!!!!!!!!!!!!!!!!!

describe ':enable', "Output Status Code Rightly" => sub {
    subtest '200 ok' => sub {
        is_status 200, 200;
    };

    subtest '400 bad request' => sub {
        is_status 400, 400;
    }
};

describe "Not Output Status Code" => sub {
    subtest '200 ok' => sub {
        is_status 200, 200;
    };

    subtest '400 bad request' => sub {
        is_status 400, 400;
    }
};

done_testing;
