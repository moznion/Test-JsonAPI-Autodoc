#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use HTTP::Response;
use Test::Mock::LWP::Conditional;

use Test::More;
use Test::JsonAPI::Autodoc;

BEGIN {
    $ENV{TEST_JSONAPI_AUTODOC} = 1;
}

my $ok_res = HTTP::Response->new(200);
$ok_res->content('{ "message" : "success" }');
$ok_res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "/foobar" => $ok_res,
);

subtest '200 OK' => sub {
    describe 'POST /foobar' => sub {
        my $req = POST '/foobar';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "get message ok");
    };

};

done_testing;
