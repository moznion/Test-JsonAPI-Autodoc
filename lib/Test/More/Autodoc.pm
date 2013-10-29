package Test::More::Autodoc;
use 5.008005;
use strict;
use warnings;
use parent qw/Exporter/;
use Carp;
use Test::More ();
use Scope::Guard;

our @EXPORT = qw/describe subtest is_status/;

our $VERSION = "0.01";

my $autodoc;

my $description;
my $context;
my $expected_status_code;

sub describe {
    if ($description) {
        return Test::More::fail; # TODO add fail message.
    }

    my $guard = sub {
        return Scope::Guard->new(sub {
            undef $autodoc;
            undef $description;
        });
    }->();

    my $autodoc_or_description  = shift;
    my $description_or_coderef = shift;

    my $code;
    # describe($description, $code)
    if (ref $description_or_coderef eq 'CODE') {
        $description = $autodoc_or_description;
        $code        = $description_or_coderef;
    }
    # describe($autodoc, $description, $code)
    else {
        $autodoc     = $autodoc_or_description;
        $description = $description_or_coderef;
        $code        = shift;
    }

    Test::More::subtest $description => $code;
}

sub subtest {
    my $guard = sub {
        return Scope::Guard->new(sub {
            undef $expected_status_code;
        });
    }->();

    my ($context, $code) = @_;

    my $result = Test::More::subtest $context => $code;

    return $result unless ($autodoc); # NOT generate document.

    # should file output as markdown {{{
    warn $description;
    warn $context;
    warn $expected_status_code;
    # }}}

    return $result;
}

sub is_status {
    my $got = shift;
    $expected_status_code = shift;

    Test::More::is $got, $expected_status_code;
}



1;
__END__

=encoding utf-8

=head1 NAME

Test::More::Autodoc - It's new $module

=head1 ** CAUTION **

This module still alpha quality. DO NOT USE THIS.

このモジュールは出来損ないだ。良い子は使わない事！

=head1 SYNOPSIS

    use Test::More::Autodoc;

=head1 DESCRIPTION

Test::More::Autodoc is ...

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

