package Test::JsonAPI::Autodoc::Request;
use strict;
use warnings;
use utf8;
use Carp;
use JSON;
use URL::Encode qw/url_params_flat/;

sub new {
    my ($class) = @_;

    bless {
    }, $class;
}

sub parse {
    my ($self, $req) = @_;

    unless ($req->isa('HTTP::Request')) {
        croak 'Request must be instance of HTTP::Request or subclass of that';
    }

    my $body         = $req->content;
    my $content_type = $req->content_type;

    my $is_json = 0;
    if ($content_type =~ m!^application/json!) {
        $body = to_json(from_json($req->decoded_content), { pretty => 1 });
        $is_json = 1;
    }

    my $target_server = '';
    if ($req->uri->scheme && $req->uri->authority) {
        $target_server = $req->uri->scheme . '://' . $req->uri->authority;
    }

    return {
        content_type => $content_type,
        method       => $req->method,
        parameters   => $self->_parse_request_parameters($body, $is_json),
        path         => $req->uri->path,
        query        => $req->uri->query,
        server       => $target_server,
    }
}

sub _parse_request_parameters {
    my ($self, $request_parameters, $is_json) = @_;

    my $parameters;
    if ($is_json) {
        $request_parameters = JSON::decode_json($request_parameters);
        $parameters = $self->_parse_json_hash($request_parameters);
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
    my ($self, $request_parameters, $layer) = @_;

    $layer = 0 unless $layer;

    my $indent = '    ' x $layer;

    my @parameters;

    if (ref $request_parameters eq 'HASH') {
        my @keys = keys %$request_parameters;
        @keys = sort {$a cmp $b} @keys;
        foreach my $key (@keys) {
            my $value = $request_parameters->{$key};
            if ( ! defined $value) {
                push @parameters, "$indent- `$key`: Nullable";
            }
            elsif ($value =~ /^\d+$/) {
                # detect number or string internally
                if (($value ^ $value) eq '0') {
                    push @parameters, "$indent- `$key`: Number (e.g. $value)";
                }
                else {
                    push @parameters, qq{$indent- `$key`: String (e.g. "$value")};
                }
            }
            elsif (ref $value eq 'HASH') {
                push @parameters, "$indent- `$key`: JSON";
                push @parameters, @{$self->_parse_json_hash($value, ++$layer)};
            }
            elsif (ref $value eq 'ARRAY') {
                push @parameters, "$indent- `$key`: Array";
                push @parameters, @{$self->_parse_json_hash($value, ++$layer)};
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
                push @parameters, @{$self->_parse_json_hash($value, ++$layer)};
            }
            elsif (ref $value eq 'ARRAY') {
                push @parameters, "$indent- Anonymous Array";
                push @parameters, @{$self->_parse_json_hash($value, ++$layer)};
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
