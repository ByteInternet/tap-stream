package TAP::Stream;

# ABSTRACT: Combine multiple TAP streams with subtests

use Moose;
use TAP::Stream::Text;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has 'stream' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[TAP::Stream::Role::ToString]',
    default => sub { [] },
    handles => {
        add_to_stream => 'push',
        is_empty      => 'is_empty',
    },
);

sub to_string {
    my $self = shift;
    return '' if $self->is_empty;

    my $to_string = '';

    my $test_number = 0;

    foreach my $next ( @{ $self->stream } ) {
        $test_number++;
        chomp( my $tap = $next->to_string );
        my $name = $next->name;
        $to_string .= $self->_build_tap( $tap, $name, $test_number );
    }
    $to_string .= "1..$test_number";
    return $to_string;
}

sub _build_tap {
    my ( $self, $tap, $name, $test_number ) = @_;

    # I don't want to hardcode this, but it's hardcoded in Test::Builder.
    # Given that I am the one who originally wrote the subtest() code in
    # Test::Builder, this ugliness is my fault - Ovid
    my $indent = '    ';

    my $failed = $self->_tap_failed($tap);
    $tap =~ s/(?<=^)/$indent/gm;
    if ($failed) {
        $tap .= "\nnot ok $test_number - $name\n# $failed\n";
    }
    else {
        $tap .= "\nok $test_number - $name\n";
    }
    return $tap;
}

sub _tap_failed {
    my ( $self, $tap ) = @_;
    my $plan_re = qr/1\.\.(\d+)/;
    my $test_re = qr/(?:not )?ok/;
    my $failed;
    my $core_tap = '';
    foreach ( split "\n" => $tap ) {
        if (/^not ok/) {    # TODO tests are not failures
            $failed++
              unless m/^ ( [^\\\#]* (?: \\. [^\\\#]* )* )
                 \# \s* TODO \b \s* (.*) $/ix
        }
        $core_tap .= "$_\n" if /^(?:$plan_re|$test_re)/;
    }
    my $plan;
    if ( $core_tap =~ /^$plan_re/ or $core_tap =~ /$plan_re$/ ) {
        $plan = $1;
    }
    return 'No plan found' unless defined $plan;
    return "Failed $failed out of $plan tests" if $failed;

    my $plans_found = 0;
    $plans_found++ while $core_tap =~ /^$plan_re/gm;
    return "$plans_found plans found" if $plans_found > 1;

    my $tests = 0;
    $tests++ while $core_tap =~ /^$test_re/gm;
    return "Planned $plan tests and found $tests tests" if $tests != $plan;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

B<Experimental> module to combine multiple TAP streams.

=head1 SYNOPSIS

    # combine two chunks of TAP into a single stream

    my $stream = TAP::Stream->new;
    $stream->add_to_stream(
        TAP::Stream::Text->new(
            name => 'foo tests',
            text => <<'END' )
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
    END
    );
    $stream->add_to_stream(
        TAP::Stream::Text->new(
            name => 'bar tests',
            text => <<'END' )
    ok 1 - bar 1
    ok 2 - bar 2
        ok 1 - bar subtest 1
        ok 2 - bar subtest 2
        not ok 2 - bar subtest 3 #TODO ignore
    not ok 3 - bar subtest
    ok 4 - bar 4
    1..4
    END
    );

Output:

        ok 1 - foo 1
        ok 2 - foo 2
        1..2
    ok 1 - foo tests
        ok 1 - bar 1
        ok 2 - bar 2
            ok 1 - bar subtest 1
            ok 2 - bar subtest 2
            not ok 2 - bar subtest 3 #TODO ignore
        not ok 3 - bar subtest
        ok 4 - bar 4
        1..4
    ok 2 - bar tests
    1..2
