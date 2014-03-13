package TAP::Stream::Role::ToString;

use Moose::Role;

requires qw(
    to_string
);
has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Unnamed TAP stream',
);


1;
