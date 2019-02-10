#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

use Mail::DMARC::PurePerl;

{
  my $bimi = Mail::BIMI->new;

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result()->result( 'pass' );
  $dmarc->result()->disposition( 'reject' );
  $bimi->dmarc_object( $dmarc->result );

  $bimi->domain( 'gallifreyburning.com' );
  $bimi->selector( 'FAKEfoobar' );

  my $record = $bimi->record();
  $record->record;

  is_deeply( $record->domain, 'gallifreyburning.com', 'Fallback domain' );
  is_deeply( $record->selector, 'default', 'Fallback selector' );
}

{
  my $bimi = Mail::BIMI->new;

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result()->result( 'pass' );
  $dmarc->result()->disposition( 'reject' );
  $bimi->dmarc_object( $dmarc->result );

  $bimi->domain( 'no.domain.gallifreyburning.com' );
  $bimi->selector( 'FAKEfoobar' );

  my $record = $bimi->record();
  $record->record;

  is_deeply( $record->domain, 'gallifreyburning.com', 'Fallback domain' );
  is_deeply( $record->selector, 'default', 'Fallback selector' );
}

done_testing;
