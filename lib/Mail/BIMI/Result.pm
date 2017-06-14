package Mail::BIMI::Result;

use strict;
use warnings;

# VERSION

use Carp;
use English qw( -no_match_vars );

sub new {
    my ( $Class, $Args ) = @_;
    my $Self = $Args;

    bless $Self, ref($Class) || $Class;
    return $Self;
}

sub get_authentication_results {
}

sub get_bimi_location {
}

1;

