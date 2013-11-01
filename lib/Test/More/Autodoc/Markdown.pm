package Test::More::Autodoc::Markdown;
use strict;
use warnings;
use utf8;
use Text::Xslate qw(mark_raw);
use Data::Section::Simple;

sub new {
    my ($class, $output_path) = @_;

    bless {
        output_path => $output_path,
    }, $class;
}

sub generate {
    my ($self, $description, $results) = @_;

    my $vpath = Data::Section::Simple->new()->get_data_section();
    my $tx = Text::Xslate->new(
        path => [$vpath],
    );

    print $tx->render('document.json.tx', {
        description => mark_raw($description),
        results     => $results,
    });
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
