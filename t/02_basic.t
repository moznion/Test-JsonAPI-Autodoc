#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use HTTP::Request::Common;
use HTTP::Response;
use Path::Tiny;
use Test::Mock::LWP::Conditional;

use Test::More;
use Test::More::Autodoc;

my $res = HTTP::Response->new(200);
$res->content('{ "message" : "success" }');
$res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "/foobar" => $res
);

describe 'POST /foobar' => sub {
    my $req = POST '/foobar';
    $req->header('Content-Type' => 'application/json');
    $req->content(q{
        {
            "id": 1,
            "message": "blah blah"
        }
    });
    http_ok($req, 200, "get message");
};

(my $filename = path($0)->basename) =~ s/\.t$//;
$filename .= '.md';
my $fh = path("$FindBin::Bin/../doc/$filename")->openr_utf8;

my $got      = do { local $/; <$fh> };
my $expected = do { local $/; <DATA> };
is $got, $expected, 'result ok';

done_testing;

__DATA__
## POST /foobar

get message

### parameters

- `id`: Number (e.g. 1)
- `message`: String (e.g. "blah blah")

### request

POST /foobar

### response

```
Status: 200
Response:
{
   "message" : "success"
}

```
