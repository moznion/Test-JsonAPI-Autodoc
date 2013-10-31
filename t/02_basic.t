#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use HTTP::Response;
use Test::Mock::LWP::Conditional;

use Test::More;
use Test::More::Autodoc;
use Capture::Tiny qw/capture_stdout/;

my $res = HTTP::Response->new(200);
$res->content('{ "message" : "success" }');
$res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "/foobar" => $res
);

my $result = capture_stdout{ # TODO
    describe 'Output Status Code Rightly' => sub {
        context 'POST /foobar' => sub {
            my $req = POST '/foobar';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            http_ok($req, 200);
        };
    };
};

is $result, <<'...', 'result ok';
# Output Status Code Rightly

## POST /foobar

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
...

done_testing;
