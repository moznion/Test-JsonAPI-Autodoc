[![Build Status](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc.png?branch=master)](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc)
# NAME

Test::JsonAPI::Autodoc - Test JSON API response and auto generate API documents



# SYNOPSIS

    use HTTP::Request::Common;
    use Test::More;
    use Test::JsonAPI::Autodoc;

    # JSON request
    describe 'POST /foo' => sub {
        my $req = POST '/foo';
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
        my $req = POST '/bar', [ id => 42, message => 'hello' ];
        http_ok($req, 200, "returns response");
    }



# DESCRIPTION

Test::JsonAPI::Autodoc tests JSON API response (only check status code).
And it generates API documents according to the response automatically.
Please refer to ["USAGE"](#USAGE) for details.

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.__



# USAGE

A document will be generated if `describe` is used instead of `Test::More::subtest`.
And call `http_ok` at inside of `describe`, then it tests API response
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
        my $req = POST '/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "returns response");
    };

The following markdown document are outputted after execution of a test
(document output to `$project\_root/docs/test.md` on default setting).

    generated at: 2013-11-02 16:56:59

    ## POST /foo

    get message ok

    ### parameters

    __application/json__

    - `id`: Number (e.g. 1)
    - `message`: String (e.g. "blah blah")

    ### request

    POST /foo

    ### response

    ```
    Status: 200
    Response:
    {
       "message" : "success"
    }

    ```



# METHODS

- describe ($description, \\&coderef)

    `describe` method can be used like `Test::More::subtest`.
    If this method is called, a document will be outputted with a test.

    `$description` will be headline of markdown documents.

    __\*\*\* DO NOT USE THIS METHOD AS NESTING \*\*\*__

- http\_ok ($request, $expected\_status\_code, $note);

    `http_ok` method tests API response (only status code).
    and convert the response to markdown document.

    `$note` will be note of markdown documents.

    When this method is not called at inside of `describe`, documents is not generated.

- set\_documents\_path

    Set the output place of a document.
    An absolute path and a relative path can be used.

- set\_template

    Set the original template. This method require the string.
    Please refer to ["CUSTOM TEMPLATE"](#CUSTOM TEMPLATE) for details.



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
    - result.location
    - result.method
    - result.query
    - result.content\_type
    - result.parameters
    - result.status
    - result.response

### Example as follows.

    : if $generated_at {
    generated at: <: $generated_at :>

    : }
    ## <: $description :>

    : for $results -> $result {
    <: $result.note :>

    ### parameters

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

    ### request

    <: $result.method:> <: $result.location :>
    : if $result.query {

        <: $result.query :>
    : }

    ### response

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



# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



# AUTHOR

moznion <moznion@gmail.com>
