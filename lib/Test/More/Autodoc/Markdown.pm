package Test::More::Autodoc::Markdown;
use strict;
use warnings;
use utf8;
use Data::Section::Simple;
use Text::Xslate qw(mark_raw);
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
    my $tx    = Text::Xslate->new(path => [$vpath]);

    my $fh;
    if ($first_time) {
        $fh = $document_path->openw_utf8( { locked => 1 } );
    }
    else {
        $fh = $document_path->opena_utf8( { locked => 1 } );
    }

    print $fh $tx->render('document.json.tx', {
        description => mark_raw($description),
        results     => $results,
    });
    close $fh;
}
1;

__DATA__
@@ document.json.tx
## <: $description :>

: for $results -> $result {
<: $result.comment :>

### parameters

: if $result.parameters {
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

