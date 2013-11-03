[![Build Status](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc.png?branch=master)](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc)
# NAME

Test::JsonAPI::Autodoc - Test JSON API response and auto generate API documents



# SYNOPSIS

    use HTTP::Request::Common;
    use Test::More;
    use Test::JsonAPI::Autodoc;

    # JSON request
    describe 'POST /foo' => sub {
        my $req = POST 'http://localhost:5000/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "returns response"); # <= Check status whether 200, and generate documents
    };

    # Can also request application/x-www-form-urlencoded
    describe 'POST /bar' => sub {
        my $req = POST 'http://localhost:3000/bar', [ id => 42, message => 'hello' ];
        http_ok($req, 200, "returns response");
    }

    # And you can use Plack::Test
    use Plack::Test;
    use Plack::Request;
    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        if ($req->path eq '/') {
            return [ 200, [ 'Content-Type' => 'application/json' ], ['{ "message" : "success" }'] ];
        }
        return [ 404, [ 'Content-Type' => 'text/plain' ], [ "Not found" ] ];
    };

    my $test_app = Plack::Test->create($app);
    describe 'POST /' => sub {
        my $req = POST '/';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
            "id": 1,
            "message": "blah blah"
            }
        });
        plack_ok($test_app, $req, 200, "get message ok");
    };

    # Of course you can use `test_psgi`
    test_psgi $app, sub {
        my $cb = shift;

        describe 'POST /not-exist' => sub {
            my $req = POST '/not-exist';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            plack_ok($cb, $req, 404, "not found");
        };
    };

# DESCRIPTION

Test::JsonAPI::Autodoc tests JSON API response (only check status code).
And it generates API documents according to the response automatically.
Please refer to ["USAGE"](#USAGE) for details.

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.__



# USAGE

A document will be generated if `describe` is used instead of `Test::More::subtest`.
And call `http_ok` or `plack_ok` at inside of `describe`, then it tests API response
and convert the response to markdown document.

Run test as follows.

    $ TEST_JSONAPI_AUTODOC=1 prove t/test.t

If `TEST_JSONAPI_AUTODOC` doesn't have true value, __documents will not generate__.

The example of `test.t` is as follows.

    use HTTP::Request::Common;
    use Test::More;
    use Test::JsonAPI::Autodoc;

    # JSON request
    describe 'POST /foo' => sub {
        my $req = POST 'http://localhost:5000/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "get message ok");
    };

The following markdown document are outputted after execution of a test.
Document will output to `$project\_root/docs/test.md` on default setting.

    generated at: 2013-11-03 22:29:06

    ## POST /foo

    get message ok

    ### Target Server

    http://localhost:5000

    ### Parameters

    __application/json__

    - `id`: Number (e.g. 1)
    - `message`: String (e.g. "blah blah")

    ### Request

    POST /foo

    ### Response

    ```
    Status: 200
    Response:
    {
       "message" : "success"
    }

    ```

Please also refer to example ([https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg](https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg)).



# METHODS

- describe ($description, \\&coderef)

    `describe` method can be used like `Test::More::subtest`.
    If this method is called, a document will be outputted with a test.

    `$description` will be headline of markdown documents.

    __\*\*\* DO NOT USE THIS METHOD AS NESTING \*\*\*__

- http\_ok ($request, $expected\_status\_code, $note)

    `http_ok` method tests API response (only status code).
    and convert the response to markdown document.

    `$note` will be note of markdown documents.

    When this method is not called at inside of `describe`, documents is not generated.

- plack\_ok ($plack\_app, $request, $expected\_status\_code, $note)

    `plack_ok` method carries out almost the same operation as `http_ok`.
    This method is for [Plack](http://search.cpan.org/perldoc?Plack) application.
    This method requires plack application as the first argument.

- set\_documents\_path

    Set the output place of a document.
    An absolute path and a relative path can be used.

- set\_template

    Set the original template. This method require the string.
    Please refer to ["CUSTOM TEMPLATE"](#CUSTOM TEMPLATE) for details.



# REQUIREMENTS

Generated document will output to `$project\_root/docs/` on default setting.
$project\_root means the directory on which `cpanfile` discovered while going
back to a root directory from a test script is put.
Therefore, __it is necessary to put `cpanfile` on a project root__.



# CONFIGURATION AND ENVIRONMENT

- TEST\_JSONAPI\_AUTODOC

    Documents are generated when true value is set to this environment variable.



# CUSTOM TEMPLATE

You can customize template of markdown documents.

Available variables are the followings.

- description
- generated\_at
- results
    - result.note
    - result.path
    - result.server
    - result.method
    - result.query
    - result.content\_type
    - result.parameters
    - result.status
    - result.response

### Example

    : if $generated_at {
    generated at: <: $generated_at :>

    : }
    ## <: $description :>

    : for $results -> $result {
    <: $result.note :>

    : if $result.server {
    ### Target Server

    <: $result.server :>
    : if $result.is_plack_app {

    (Plack application)
    : }

    :}
    ### Parameters

    : if $result.parameters {
        : if $result.content_type {
    __<: $result.content_type :>__

        : }
    : for $result.parameters -> $parameter {
    <: $parameter :>
    : }
    : }
    : else {
    Not required
    : }

    ### Request

    <: $result.method:> <: $result.path :>
    : if $result.query {

        <: $result.query :>
    : }

    ### Response

    ```
    Status: <: $result.status :>
    Response:
    <: $result.response :>
    : }
    ```

Template needs to be written by [Text::Xslate::Syntax::Kolon](http://search.cpan.org/perldoc?Text::Xslate::Syntax::Kolon) as looking.



# INSPIRED

This module is inspired by “autodoc”, which is written by Ruby. That is very nice RSpec extension.

See also [https://github.com/r7kamura/autodoc](https://github.com/r7kamura/autodoc)



# NOTE

This module is developing. I think that there is much bug in this module. I am waiting for your report!



# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



# AUTHOR

moznion <moznion@gmail.com>
