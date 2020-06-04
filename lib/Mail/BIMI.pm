package Mail::BIMI;
# ABSTRACT: BIMI object
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Record;
use Mail::BIMI::Result;
use Mail::DMARC::PurePerl;
  with 'Mail::BIMI::Role::Options';
  with 'Mail::BIMI::Role::Resolver';
  with 'Mail::BIMI::Role::Error';
  has domain => ( is => 'rw', isa => Str, required => 0,
    documentation => 'Domain to lookup/domain record was retrieved from', pod_section => 'inputs' );
  has selector => ( is => 'rw', isa => Str, lazy => 1, builder => sub{ return 'default' }, documentation => 'The selector to query, assume default if null',
    documentation => 'Selector to lookup/selector record was retrieved from', pod_section => 'inputs' );
  has dmarc_object => ( is => 'rw', isa => sub{!defined $_[0] || class_type('Mail::DMARC::PurePerl') || class_type('Mail::DMARC::Result')},
    documentation => 'validated Mail::DMARC::PurePerl object from parsed message', pod_section => 'inputs' );
  has spf_object => ( is => 'rw', isa => class_type('Mail::SPF::Result'),
    documentation => 'Mail::SPF::Result object from parsed message', pod_section => 'inputs' );
  has dmarc_result_object => ( is => 'rw', isa => sub{!defined $_[0] || class_type('Mail::DMARC::Result')}, lazy => 1, builder => '_build_dmarc_result_object',
    documentation => 'Relevant Mail::DMARC::Result object' );
  has dmarc_pp_object => ( is => 'rw', isa => sub{!defined $_[0] || class_type('Mail::DMARC::PurePerl')}, lazy => 1, builder => '_build_dmarc_pp_object',
    documentation => 'Relevant Mail::DMARC::PurePerl object' );
  has record => ( is => 'rw', lazy => 1, builder => '_build_record',
    documentation => 'Mail::BIMI::Record object' );
  has result => ( is => 'rw', lazy => 1, builder => '_build_result',
    documentation => 'Mail::BIMI::Result object' );
  has time => ( is => 'ro', lazy => 1, builder => sub{return time},
    documentation => 'time of retrieval - useful in testing' );

sub _build_dmarc_result_object($self) {
  return $self->dmarc_object->result if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  return $self->dmarc_object         if ref $self->dmarc_object eq 'Mail::DMARC::Result';
  return;
}

sub _build_dmarc_pp_object($self) {
  return $self->dmarc_object if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->set_resolver($self->resolver);
  $dmarc->header_from($self->domain);
  $dmarc->validate;
  return $dmarc;
}

sub _build_record($self) {
  croak 'Domain required' if ! $self->domain;
  return Mail::BIMI::Record->new( domain => $self->domain, selector => $self->selector, resolver => $self->resolver, bimi_object => $self );
}

sub _build_result($self) {
  croak 'Domain required' if ! $self->domain;

  my $result = Mail::BIMI::Result->new(
    bimi_object => $self,
    headers => {},
  );

  # does DMARC pass
  if ( ! $self->dmarc_result_object ) {
    $result->set_result( 'skipped', $self->ERR_NO_DMARC );
    return $result;
  }
  if ( $self->dmarc_result_object->result ne 'pass' ) {
      $result->set_result( 'skipped', 'DMARC ' . $self->dmarc_result_object->result );
      return $result;
  }

  # Is DMARC enforcing?
  my $dmarc = $self->dmarc_pp_object;
  if (exists $dmarc->result->{published}){
    my $published_policy = $dmarc->result->published->p // '';
    my $published_subdomain_policy = $dmarc->result->published->sp // '';
    my $published_policy_pct = $dmarc->result->published->pct // 100;
    my $effective_published_policy = ( $dmarc->is_subdomain && $published_subdomain_policy ) ? lc $published_subdomain_policy : lc $published_policy;
    if ( $effective_published_policy eq 'quarantine' && $published_policy_pct ne '100' ) {
      $result->set_result( 'skipped', $self->ERR_DMARC_NOT_ENFORCING );
      return $result;
    }
    if ( $effective_published_policy ne 'quarantine' && $effective_published_policy ne 'reject' ) {
      $result->set_result( 'skipped', $self->ERR_DMARC_NOT_ENFORCING );
      return $result;
    }
    if ( $published_subdomain_policy && $published_subdomain_policy eq 'none' ) {
      $result->set_result( 'skipped', $self->ERR_DMARC_NOT_ENFORCING );
      return $result;
    }
  }
  else {
    $result->set_result( 'skipped', $self->ERR_NO_DMARC );
    return $result;
  }

  if ( $self->spf_object ) {
      my $spf_request = $self->spf_object->request;
      if ( $spf_request ) {
          my $spf_record = $spf_request->record;
          if ( $spf_record ) {
              my @spf_terms = $spf_record->terms;
              if ( @spf_terms ) {
                    my $last_term = pop @spf_terms;
                    if ( $last_term->name eq 'all' && $last_term->qualifier eq '+') {
                        $result->set_result( 'skipped', $self->ERR_SPF_PLUS_ALL );
                        return $result;
                    }
                }
            }
        }
    }

  if ( ! $self->record->is_valid ) {
    if ( $self->record->has_error( $self->ERR_NO_BIMI_RECORD ) ) {
      $result->set_result( 'none', $self->ERR_BIMI_NOT_ENABLED );
    }
    elsif ( $self->record->has_error( $self->ERR_DNS_ERROR ) ) {
      $result->set_result( 'none', $self->ERR_DNS_ERROR );
    }
    else {
      my @fail_errors = qw{
        ERR_NO_DMARC
        ERR_MULTI_BIMI_RECORD
        ERR_DUPLICATE_KEY
        ERR_EMPTY_L_TAG
        ERR_EMPTY_V_TAG
        ERR_INVALID_V_TAG
        ERR_MISSING_L_TAG
        ERR_MISSING_V_TAG
        ERR_MULTIPLE_AUTHORITIES
        ERR_MULTIPLE_LOCATIONS
        ERR_INVALID_TRANSPORT_A
        ERR_INVALID_TRANSPORT_L
        ERR_SPF_PLUS_ALL
        ERR_SVG_FETCH_ERROR
        ERR_VMC_FETCH_ERROR
        ERR_VMC_PARSE_ERROR
        ERR_VMC_VALIDATION_ERROR
        ERR_SVG_GET_ERROR
        ERR_SVG_SIZE
        ERR_SVG_UNZIP_ERROR
        ERR_SVG_INVALID_XML
        ERR_SVG_VALIDATION_ERROR
        ERR_SVG_MISMATCH
        ERR_VMC_REQUIRED
      };
      my $found_error = 0;

      foreach my $fail_error (@fail_errors) {
        if ( $self->record->has_error( $self->$fail_error ) ) {
          $found_error = 1;
          $result->set_result( 'fail', $self->$fail_error );
          last;
        }
      }
      if ( !$found_error ) {
        $result->set_result( 'fail', $self->ERR_BIMI_INVALID );
      }
    }
    return $result;
  }

  my @bimi_location;
  if ( $self->record->authority && $self->record->authority->is_relevant ) {
    push @bimi_location, '    l='.$self->record->location->location if $self->record->location_is_relevant;
    push @bimi_location, '    a='.$self->record->authority->authority;
    $result->headers->{'BIMI-Indicator'} = $self->record->authority->vmc->indicator->header;
  }
  else {
    push @bimi_location, '    l='.$self->record->location->location;
    $result->headers->{'BIMI-Indicator'} = $self->record->location->indicator->header;
  }

  $result->headers->{'BIMI-Location'} = join( "\n",
    'v=BIMI1;',
    @bimi_location,
  );

  $result->set_result( 'pass', '' );

  return $result;
}

1;
