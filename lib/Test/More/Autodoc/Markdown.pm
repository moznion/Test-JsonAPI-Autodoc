package Test::More::Autodoc::Markdown;
use strict;
use warnings;
use utf8;
use Data::Section::Simple;
use Time::Piece;
use Text::Xslate qw(mark_raw);
use Text::Xslate::Bridge::Star;
use Test::More::Autodoc::Path;

sub new {
    my ($class, $output_path) = @_;

    bless {
        output_path => $output_path,
    }, $class;
}

sub generate {
    my ($self, $description, $results, $first_time) = @_;

    my $document_path = Test::More::Autodoc::Path->document_path($self->{output_path});

    my $vpath = Data::Section::Simple->new()->get_data_section();
    my $tx    = Text::Xslate->new(
        type => 'text',
        path => [$vpath],
        module => ['Text::Xslate::Bridge::Star'],
    );

    my $fh;
    my $generated_at;
    if ($first_time) {
        $fh = $document_path->openw_utf8( { locked => 1 } );
        $generated_at = localtime->strftime('%Y-%m-%d %H:%M:%S');
    }
    else {
        $fh = $document_path->opena_utf8( { locked => 1 } );
    }

    print $fh $tx->render('document.json.tx', {
        generated_at => $generated_at,
        description  => $description,
        results      => $results,
    });
    close $fh;
}
1;

__DATA__
@@ document.json.tx
: if $generated_at {
generated at: <: $generated_at :>

: }
## <: $description :>

: for $results -> $result {
<: $result.comment :>

### parameters

: if $result.parameters {
    : if $result.content_type.match(rx('^application/json')) {
__application/json__
    : }
    : else {
__application/x-www-form-urlencoded__
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

