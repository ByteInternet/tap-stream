package TAP::Stream::Text;

use Moose;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub to_string { shift->text }

__PACKAGE__->meta->make_immutable;

1;
