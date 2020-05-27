#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Pragmas;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC::PurePerl;
use Mail::SPF::Server;
use Mail::SPF::Request;
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');

my $spf_server = Mail::SPF::Server->new(
  'dns_resolver' => $resolver,
);

my $spf_request = Mail::SPF::Request->new(
 'versions'      => [1],
 'scope'         => 'mfrom',
 'identity'      => 'test@spfnall.gallifreyburning.com',
 'ip_address'    => '66.111.4.25',
 'helo_identity' => 'spfnall.galllifreyburning.com',
);

my $spf_result = $spf_server->process($spf_request);

my $bimi = Mail::BIMI->new();
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );
$bimi->spf_object( $spf_result );

$bimi->domain( 'spfall.gallifreyburning.com' );
$bimi->selector( 'default' );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=pass header.d=spfall.gallifreyburning.com header.selector=default';
is( $auth_results, $expected_result, 'Auth results correcct' );

my $expected_headers = {
          'BIMI-Indicator' => 'PHN2ZyBiYXNlUHJvZmlsZT0idGlueSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMD
    Avc3ZnIiB3aWR0aD0iMTAyNCIgaGVpZ2h0PSIxMDI0IiB2aWV3Qm94PSIwIDAgMTAyNCAx
    MDI0Ij48dGl0bGU+Rk0tSWNvbi1SR0I8L3RpdGxlPjxnIGlkPSJBcnR3b3JrIj48cmVjdC
    B3aWR0aD0iMTAyNCIgaGVpZ2h0PSIxMDI0IiBmaWxsPSIjRkZGRkZGIi8+PHBhdGggZD0i
    TTEyMC4xNiw1MTJjMC0yMTYuNCwxNzUuNDMtMzkxLjg0LDM5MS44NC0zOTEuODQsMTM2LD
    AsMjU1LjcxLDY5LjM0LDMyNiwxNzQuNTNsNzcuMTksMTUuMjEsOS41OC03My4wNmMtODkt
    MTMzLjE4LTI0MC41Ni0yMjEtNDEyLjc0LTIyMUMyMzgsMTUuODcsMTUuODcsMjM4LDE1Lj
    g3LDUxMkE0OTMuNzgsNDkzLjc4LDAsMCwwLDk5LjE5LDc4Ny4yMWw3NC43Miw5LjY4TDE4
    Niw3MjkuMzVBMzkwLDM5MCwwLDAsMSwxMjAuMTYsNTEyWiIgZmlsbD0iIzAwNjdiOSIvPj
    xwYXRoIGQ9Ik05MjYsMjM4LjY0Yy0uNDEtLjYxLS44My0xLjItMS4yNC0xLjhMODM4LDI5
    NC42OWMuNDEuNi44MywxLjE5LDEuMjMsMS44QTM4OS45MSwzODkuOTEsMCwwLDEsOTAzLj
    gzLDUxMmMwLDIxNi40LTE3NS40MywzOTEuODQtMzkxLjgzLDM5MS44NC0xMzUuMjEsMC0y
    NTQuNDItNjguNDktMzI0Ljg0LTE3Mi42Ni0uNDEtLjYtLjc5LTEuMjItMS4xOS0xLjgzTD
    k5LjE5LDc4Ny4yMWMuNDEuNi43OCwxLjIyLDEuMTksMS44M0MxODkuNTEsOTIxLjIsMzQw
    LjYsMTAwOC4xMyw1MTIsMTAwOC4xM2MyNzQsMCw0OTYuMTMtMjIyLjEzLDQ5Ni4xMy00OT
    YuMTNBNDkzLjY4LDQ5My42OCwwLDAsMCw5MjYsMjM4LjY0WiIgZmlsbD0iIzY5YjNlNyIv
    PjxwYXRoIGQ9Ik01MTIsNTEyLDI3Ni4xNSwzNTQuNzZWNjY5LjIzaDBsMTQ4LjItNDUuOD
    ZaIiBmaWxsPSIjZmZjMTA3Ii8+PHBhdGggZD0iTTI3Ni4xNSw2NjkuMjRINzMxLjI3YTE2
    LjU4LDE2LjU4LDAsMCwwLDE2LjU4LTE2LjU5VjM1NC43NloiIGZpbGw9IiMzMzNlNDgiLz
    48L2c+PC9zdmc+Cg==',
          'BIMI-Location' => 'v=BIMI1;
    l=https://fastmaildmarc.com/FM_BIMI.svg'
        };
is_deeply( $result->headers, $expected_headers, 'headers' );

done_testing;