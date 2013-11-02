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

our $VERSION = "0.05";

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
    my ($req, $expected_code, $note) = @_;

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
    return unless $in_describe;

    my $response_body = $res->content;
    if($res->content_type =~ m!^application/json!) {
        $response_body = to_json(from_json($res->decoded_content), { pretty => 1 });
    }

    push @$results, +{
        note         => $note,

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

Test::JsonAPI::Autodoc tests JSON API response (only check status code).
And it generates API documents according to the response automatically.
Please refer to L<"USAGE"> for details.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.>


=head1 USAGE

A document will be generated if C<describe> is used instead of C<Test::More::subtest>.
And call C<http_ok> at inside of C<describe>, then it tests API response
and convert the response to markdown document.

Run test as follows.

    $ TEST_JSONAPI_AUTODOC=1 prove t/test.t

If C<TEST_JSONAPI_AUTODOC> doesn't have true value, B<documents will not generate>.

The example of F<test.t> is as follows.

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

The following markdown document are outputted after execution of a test.
Document will output to F<$project_root/docs/test.md> on default setting.

=begin text

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

=end text

Please also refer to example (L<https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg>).


=head1 METHODS

=over 4

=item * describe ($description, \&coderef)

C<describe> method can be used like C<Test::More::subtest>.
If this method is called, a document will be outputted with a test.

C<$description> will be headline of markdown documents.

B<*** DO NOT USE THIS METHOD AS NESTING ***>

=item * http_ok ($request, $expected_status_code, $note);

C<http_ok> method tests API response (only status code).
and convert the response to markdown document.

C<$note> will be note of markdown documents.

When this method is not called at inside of C<describe>, documents is not generated.

=item * set_documents_path

Set the output place of a document.
An absolute path and a relative path can be used.

=item * set_template

Set the original template. This method require the string.
Please refer to L<CUSTOM TEMPLATE> for details.

=back


=head1 REQUIREMENTS

Generated document will output to F<$project_root/docs/> on default setting.
$project_root means the directory on which F<cpanfile> discovered while going
back to a root directory from a test script is put.
Therefore, B<it is necessary to put F<cpanfile> on a project root>.


=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item * TEST_JSONAPI_AUTODOC

Documents are generated when true value is set to this environment variable.

=back


=head1 CUSTOM TEMPLATE

You can customize template of markdown documents.

Available variables are the followings.

=over 4

=item * description

=item * generated_at

=item * results

=over 4

=item * result.note

=item * result.location

=item * result.method

=item * result.query

=item * result.content_type

=item * result.parameters

=item * result.status

=item * result.response

=back

=back

=head3 Example

=begin text

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

=end text

Template needs to be written by L<Text::Xslate::Syntax::Kolon> as looking.


=head1 INSPIRED

This module is inspired by “autodoc”, which is written by Ruby. That is very nice RSpec extension.

See also L<https://github.com/r7kamura/autodoc>


=head1 NOTE

This module is developing. I think that there is much bug in this module. I am waiting for your report!


=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut
