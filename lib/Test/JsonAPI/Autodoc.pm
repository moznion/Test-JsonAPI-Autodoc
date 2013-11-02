package Test::JsonAPI::Autodoc;
use 5.008005;
use strict;
use warnings;
use parent qw/Exporter/;
use Carp;
use Test::More ();
use Scope::Guard;
use JSON;
use LWP::UserAgent;
use URL::Encode qw/url_params_flat/;
use Test::JsonAPI::Autodoc::Markdown;

our @EXPORT = qw/describe http_ok set_documents_path set_template/;

our $VERSION = "0.01";

my $in_describe;
my $results;
my $first_time;

my $output_path;
my $template;

BEGIN {
    $first_time = 1;
}

sub describe {
    if ($in_describe) {
        croak '`describe` must not call as nesting';
    }

    my $guard = sub {
        return Scope::Guard->new(sub {
            undef $in_describe;
            undef $results;
            undef $first_time;
        });
    }->();

    $in_describe = 1;

    my ($description, $coderef) = @_;

    my $result = Test::More::subtest($description => $coderef);

    if ($result && $ENV{TEST_JSONAPI_AUTODOC}) {
        Test::JsonAPI::Autodoc::Markdown->new($output_path, $template)->generate($description, $results, $first_time);
    }
}

sub http_ok {
    my ($req, $expected_code, $comment) = @_;

    unless ($req->isa('HTTP::Request')) {
        croak 'Request must be instance of HTTP::Request or subclass of that';
    }

    my $request_body = $req->content;
    my $content_type = $req->content_type;

    my $is_json = 0;
    if($content_type =~ m!^application/json!) {
        $request_body = to_json(from_json($req->decoded_content), { pretty => 1 });
        $is_json = 1;
    }

    my $res = LWP::UserAgent->new->request($req);

    my $result = Test::More::is $res->code, $expected_code;
    return unless $result;

    my $response_body = $res->content;
    if($res->content_type =~ m!^application/json!) {
        $response_body = to_json(from_json($res->decoded_content), { pretty => 1 });
    }

    push @$results, +{
        comment      => $comment,

        location     => $req->uri->path,
        method       => $req->method,
        query        => $req->uri->query,
        content_type => $content_type,
        parameters   => _parse_request_parameters($request_body, $is_json),

        status       => $expected_code,
        response     => $response_body,
    };
}

sub set_documents_path {
    $output_path = shift;
}

sub set_template {
    $template = shift;
}

sub _parse_request_parameters {
    my ($request_parameters, $is_json) = @_;

    my $parameters;
    if($is_json) {
        $request_parameters = JSON::decode_json($request_parameters);
        $parameters = _parse_json_hash($request_parameters);
    }
    else {
        my @parameters = @{url_params_flat($request_parameters)};
        my @keys = @parameters[ grep { ! ($_ % 2) } 0 .. $#parameters ];
        @parameters = map { "- `$_`" } @keys;
        $parameters = \@parameters;
    }

    return $parameters;
}

sub _parse_json_hash {
    my ($request_parameters, $layer) = @_;

    $layer = 0 unless $layer;

    my $indent = '    ' x $layer;

    my @parameters;

    # TODO NOT GOOD (should be extracted to each method)
    if (ref $request_parameters eq 'HASH') {
        my @keys = keys %$request_parameters;
        @keys = sort {$a cmp $b} @keys;
        foreach my $key (@keys) {
            my $value = $request_parameters->{$key};
            if ($value =~ /^\d/) {
                push @parameters, "$indent- `$key`: Number (e.g. $value)";
            }
            elsif (ref $value eq 'HASH') {
                push @parameters, "$indent- `$key`: JSON";
                push @parameters, @{_parse_json_hash($value, ++$layer)};
            }
            elsif (ref $value eq 'ARRAY') {
                push @parameters, "$indent- `$key`: Array";
                push @parameters, @{_parse_json_hash($value, ++$layer)};
            }
            else {
                push @parameters, qq{$indent- `$key`: String (e.g. "$value")};
            }
        }
    }
    else {
        foreach my $value (@$request_parameters) {
            if ($value =~ /^\d/) {
                push @parameters, "$indent- Number (e.g. $value)";
            }
            elsif (ref $value eq 'HASH') {
                push @parameters, "$indent- Anonymous JSON";
                push @parameters, @{_parse_json_hash($value, ++$layer)};
            }
            elsif (ref $value eq 'ARRAY') {
                push @parameters, "$indent- Anonymous Array";
                push @parameters, @{_parse_json_hash($value, ++$layer)};
            }
            else {
                push @parameters, qq{$indent- String (e.g. "$value")};
            }
            $layer--;
        }
    }

    return \@parameters;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::JsonAPI::Autodoc - Test JSON API response and auto generate API documents


=head1 SYNOPSIS

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


=head1 DESCRIPTION

TBD

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.>


=head1 USAGE



=head1 METHODS

=head1 INSPIRED

This module is inspired by “autodoc”, which is written by Ruby. That is very nice RSpec extension.

See also L<https://github.com/r7kamura/autodoc>


=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut
