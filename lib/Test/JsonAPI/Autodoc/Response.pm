package Test::JsonAPI::Autodoc::Response;
use strict;
use warnings;
use utf8;
use JSON;

sub new {
    my ($class) = @_;

    bless {
    }, $class;
}

sub parse {
    my ($self, $res) = @_;

    my $body = $res->content;
    if ($res->content_type =~ m!^application/json!) {
        $body = to_json(from_json($res->decoded_content), { pretty => 1 });
    }

    return {
        body => $body,
    };
}

1;
