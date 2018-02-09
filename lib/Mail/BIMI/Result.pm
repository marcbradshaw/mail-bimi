package Mail::BIMI::Result;

use strict;
use warnings;

# VERSION

use Carp;
use English qw( -no_match_vars );

use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Comment;

sub new {
    my ( $Class ) = @_;
    my $Self = {
        'domain' => '',
        'selector' => '',
        'result' => '',
        'result_comment' => '',
    };

    bless $Self, ref($Class) || $Class;
    return $Self;
}

sub set_domain {
    my ( $Self, $Domain ) = @_;
    $Self->{ 'domain' } = $Domain;
    return;
}

sub set_selector {
    my ( $Self, $Selector ) = @_;
    $Self->{ 'selector' } = $Selector;
    return;
}

sub set_result {
    my ( $Self, $Result, $Comment ) = @_;
    $Self->{ 'result' } = $Result;
    $Self->{ 'result_comment' } = $Comment;
    return;
}

sub result {
    my ( $Self ) = @_;
    return $Self->{ 'result' };
}

sub get_authentication_results_object {
    my ( $Self ) = @_;
    my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'bimi' )->safe_set_value( $Self->{ 'result' } );
    if ( $Self->{ 'result_comment' } ) {
        $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( $Self->{ 'result_comment' } ) );
    }
    if ( $Self->{ 'result' } eq 'pass' ) {
        $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.d' )->safe_set_value( $Self->{ 'domain' } ) );
        $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'selector' )->safe_set_value( $Self->{ 'selector' } ) );
    }
    return $header;
}

sub get_authentication_results {
    my ( $Self ) = @_;
    return $Self->get_authentication_results_object->as_string();
}

sub get_bimi_location {
}

1;

