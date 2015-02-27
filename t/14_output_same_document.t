#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use Path::Tiny;
use Plack::Test;
use Plack::Request;

use Test::More;
use Test::JsonAPI::Autodoc;

BEGIN {
    $ENV{TEST_JSONAPI_AUTODOC} = 1;
}

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [
            '{
                "hoge": {
                    "a": "aa",
                    "b": "bb"
                }
            }'
        ],
        ['{ "message" : "success" }']
    ];
};

my $tempdir = Path::Tiny->tempdir('test-jsonapi-autodoc-XXXXXXXX');
set_documents_path($tempdir);

my $sample_doc = do { local $/; <DATA> };
my $expected;
for (1..50) {
    test_psgi $app, sub {
        my $cb = shift;

        describe 'POST /' => sub {
            my $req = POST '/';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            plack_ok($cb, $req, 200, "get message ok");
        };
    };

    $expected .= $sample_doc;
}

(my $filename = path($0)->basename) =~ s/\.t$//;
$filename .= ".md";
my $fh = path("$tempdir/$filename")->openr_utf8;

chomp (my $generated_at_line = <$fh>);
<$fh>; # blank
my $got = do { local $/; <$fh> };
is $got, $expected, 'result ok';

done_testing;

__DATA__
## POST /

get message ok

### Target Server

http://localhost

(Plack application)

### Parameters

__application/json__

- `id`: Number (e.g. 1)
- `message`: String (e.g. "blah blah")

### Request

POST /

### Response

- Status:       200
- Content-Type: application/json

```json
{
   "hoge" : {
      "a" : "aa",
      "b" : "bb"
   }
}

```

