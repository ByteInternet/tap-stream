# NAME

TAP::Stream - Combine multiple TAP streams with subtests

# VERSION

version 0.01

# SYNOPSIS

    use TAP::Stream;
    use TAP::Stream::Text;

    my $tap1 = <<'END';
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
    END

    # note that we have a failing test
    my $tap2 = <<'END';
    ok 1 - bar 1
    ok 2 - bar 2
        1..3
        ok 1 - bar subtest 1
        ok 2 - bar subtest 2
        not ok 3 - bar subtest 3 #TODO ignore
    ok 3 - bar subtest
    not ok 4 - bar 4
    1..4
    END

    my $stream = TAP::Stream->new;

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

    print $stream->to_string;

Output:

        ok 1 - foo 1
        ok 2 - foo 2
        1..2
    ok 1 - foo tests
        ok 1 - bar 1
        ok 2 - bar 2
            1..3
            ok 1 - bar subtest 1
            ok 2 - bar subtest 2
            not ok 3 - bar subtest 3 #TODO ignore
        ok 3 - bar subtest
        not ok 4 - bar 4
        1..4
    not ok 2 - bar tests
    # Failed 1 out of 4 tests
    1..2

# DESCRIPTION

Sometimes you find yourself needing to merge multiple streams of TAP.
Several use cases:

- Merging results from parallel tests
- Running tests across multiple boxes and fetching their TAP
- Saving TAP and reassembling it later

[TAP::Stream](https://metacpan.org/pod/TAP::Stream) allows you to do this. You can both merge multiple chunks of
TAP text, or even multiple `TAP::Stream` objects.

# DESCRIPTION

__Experimental__ module to combine multiple TAP streams.

# METHODS

## `new`

    my $stream = TAP::Stream->new( name => 'Parent stream' );

Creates a TAP::Stream object. The name is optional, but highly recommend to be
unique. The top-level stream's name is not used, but if you use
`add_to_stream` to add another stream object, that stream object should be
named or else the summary `(not) ok` line will be named `Unnamed TAP stream`
and this may make it harder to figure out which stream contained a failure.

Names should be descriptive of the use case of the stream.

## `name`

    my $name = $stream->name;

A read/write string accessor.

Returns the name of the stream. Default to `Unnamed TAP stream`. If you add
this stream to another stream, consider naming this stream for a more useful
TAP output. This is used to create the subtest summary line:

        1..2
        ok 1 - some test
        ok 2 - another test
    ok 1 - this is $stream->name

## `add_to_stream`

    $stream->add_to_stream(TAP::Stream::Text->new(%args));
    # or
    $stream->add_to_stream($another_stream);

Add a [TAP::Stream::Text](https://metacpan.org/pod/TAP::Stream::Text) object or another [TAP::Stream](https://metacpan.org/pod/TAP::Stream) object. You may
call this method multiple times. The following two chunks of code are the
same:

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

Versus:

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
    );
    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

Stream objects can be added to other stream objects:

    my $parent = TAP::Stream->new; # the name is unused for the parent

    my $stream = TAP::Stream->new( name => 'child stream' );

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );
    $parent->add_to_stream($stream);

    # later:
    $parent->add_to_stream($another_stream);
    $parent->add_to_stream(TAP::Stream::Text->new%args);
    $parent->add_to_stream($yet_another_stream);

    say $parent->to_string;

## `to_string`

    say $stream->to_string;

Prints the stream as TAP. We do not overload stringification.

# HOW IT WORKS

Each chunk of TAP (or stream) that is added is added as a subtest. This avoids
issues of trying to recalculate the numbers. This means that if you
concatenate three TAP streams, each with 25 tests, you will still see 3 tests
reported (because you have three subtests).

There is a mini-TAP parser within `TAP::Stream`. As you add a chunk of TAP or
a stream, the parser analyzes the TAP and if there is a failure, the subtest
itself will be reported as a failure. Causes of failure:

- Any failing tests (TODO tests, of course, are not failures)
- No plan
- Number of tests do not match the plan
- More than one plan

# CAVEATS

- Out-of-sequence tests not handled

    Currently we do not check for tests out of sequence because, in theory, test
    numbers are strictly optional in TAP. Make sure your TAP emitters Do The Right
    Thing. Patches welcome.

- Partial streams not handled

    Each chunk of TAP added must be a complete chunk of TAP, complete with a plan.
    You can't add tests 1 through 3, and then 4 through 7.

# AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
