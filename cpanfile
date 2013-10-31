requires 'JSON';
requires 'LWP::UserAgent';
requires 'Scope::Guard';
requires 'Test::More', '0.98';
requires 'Text::Xslate';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'HTTP::Request::Common';
    requires 'HTTP::Response';
    requires 'Test::Mock::LWP::Conditional';
};
