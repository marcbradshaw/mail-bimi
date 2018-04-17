package Mail::BIMI::Record;

use strict;
use warnings;

# VERSION

use Carp;
use English qw( -no_match_vars );

sub new {
    my ( $Class, $Args ) = @_;

    my $Self = {};
    bless $Self, ref($Class) || $Class;

    $Self->{ 'record' } = $Args->{ 'record' };
    $Self->{ 'domain' } = $Args->{ 'domain' } || q{};
    $Self->{ 'selector' } = $Args->{ 'selector' } || q{};
    $Self->{ 'url_list' } = [];
    $Self->{ 'data' }     = {};
    $Self->{ 'error' }    = [];

    if ( my $Record = $Self->{ 'record' } ) {
        $Self->parse_record();
        $Self->validate_record();
        $Self->construct_url_list();
    }
    else {
        $Self->error( 'No record supplied' );
    }

    return $Self;
}

sub error {
    my ( $Self, $Error ) = @_;
    if ( $Error ) {
        push @{ $Self->{ 'error' } } , $Error;
        return;
    }
    else {
        return join( ', ', @{ $Self->{ 'error' } } );
    }
}

sub is_valid {
    my ( $Self ) = @_;
    if ( scalar @{ $Self->{ 'error' } } > 0 ) {
        return 0;
    }
    return 1;
}

sub parse_record {
    my ( $Self ) = @_;
    my $Record = $Self->{ 'record' };

    my $Data = {};
    my @Parts = split ';', $Record;
    foreach my $Part ( @Parts ) {
        $Part =~ s/^ +//;
        $Part =~ s/ +$//;
        my ( $Key, $Value ) = split '=', $Part, 2;
        $Key = lc $Key;
        if ( exists $Data->{ $Key } ) {
            $Self->error( 'Duplicate key in record' );
        }
        if ( $Key eq 'v' || $Key eq 'a' ) {
            $Data->{ $Key } = $Value;
        }
        elsif ( $Key eq 'l' ) {
            my @Values = split ',', $Value;
            $Data->{ $Key } = \@Values;
        }
        else {
            #$Self->error( 'Record has unknown tag' ); # This is to be ignored
        }
    }
    $Self->{ 'data' } = $Data;
    return;
}

sub data {
    my ( $Self ) = @_;
    return $Self->{ 'data' };
}

sub construct_url_list {
    my ( $Self ) = @_;
    my @UrlList;
    # Need to decode , and ; as per spec
    foreach my $Location ( @{ $Self->{ 'data' }->{ 'l' } } ) {
        push @UrlList, $Location; ## TODO, should this have '.svg' appended?
    }
    $Self->{ 'url_list' } = \@UrlList;
    return;
}

sub url_list {
    my ( $Self ) = @_;
    return $Self->{ 'url_list' };
}

sub validate_record {
    my ( $Self ) = @_;
    my $Data = $Self->{ 'data' };

    # Missing or invalid v
    if ( ! exists ( $Data->{ 'v' } ) ) {
        $Self->error( 'Missing v tag' );
    }
    else {
        $Self->error( 'Empty v tag' ) if lc $Data->{ 'v' } eq '';
        $Self->error( 'Invalid v tag' ) if lc $Data->{ 'v' } ne 'bimi1';
    }

    # Missing l
    # Invalid l url
    # l is hot https://
    if ( ! exists ( $Data->{ 'l' } ) ) {
        $Self->error( 'Missing l tag' );
    }
    else {
        if ( scalar @{ $Data->{ 'l' } } == 0 ) {
                $Self->error( 'Empty l tag' );
        }
        else {
            foreach my $l ( @{ $Data->{ 'l' } } ) {
                $Self->error( 'Empty l tag' ) if $l eq '';
                if ( ! ( $l =~ /^https:\/\// ) ) {
                    $Self->error( 'Invalid transport in l tag' );
                }
            }
        }
    }

    # Validate a auth

    return;
}

1;
