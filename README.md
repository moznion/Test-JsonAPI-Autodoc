[![Build Status](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc.png?branch=master)](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc)
# NAME

Test::JsonAPI::Autodoc - Test API response and auto generate API documents



# SYNOPSIS

    use Test::JsonAPI::Autodoc;
    use Test::More;

    describe 'POST /foobar' => sub {
        my $req = POST '/foobar';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "returns response");
    };

# DESCRIPTION

TBD

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.__

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
