use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

plan tests => 9;

is_deeply(
    test_record( 'v=bimi1; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 1, '' ],
    'Valid record'
);

is_deeply(
    test_record( 'v=bimi1; v=bimi2; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 0, 'Duplicate key in record, Invalid v tag' ],
    'Dupliacte key'
);

is_deeply(
    test_record( 'l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 0, 'Missing v tag' ],
    'Missing v tag'
);
is_deeply(
    test_record( 'v=; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 0, 'Empty v tag, Invalid v tag' ],
    'Empty v tag'
);
is_deeply(
    test_record( 'v=foobar; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 0, 'Invalid v tag' ],
    'Invalid v tag'
);

is_deeply(
    test_record( 'v=bimi1; z=256x256,512x512,1024x1024', 'example.com', 'default' ),
    [ 0, 'Missing l tag' ],
    'Missing l tag'
);
is_deeply(
    test_record( 'v=bimi1; l=http://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
    [ 0, 'Invalid transport in l tag' ],
    'Invalid transport in l tag'
);
is_deeply(
    test_record( 'v=bimi1; l=foo,,bar', 'example.com', 'default' ),
    [ 0, 'Invalid transport in l tag, Empty l tag, Invalid transport in l tag, Invalid transport in l tag' ],
    'Empty l entry'
);
is_deeply(
    test_record( 'v=bimi1; l=', 'example.com', 'default' ),
    [ 0, 'Empty l tag' ],
    'Empty l tag'
);

sub test_record {
    my ( $Entry, $Domain, $Selector ) = @_;
    my $Record = Mail::BIMI::Record->new({ 'record' => $Entry, 'domain' => $Domain, 'selector' => $Selector });
    return [ $Record->is_valid(), $Record->error() ];;
}

#!perl
