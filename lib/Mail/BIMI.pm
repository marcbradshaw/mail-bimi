package Mail::BIMI;
# ABSTRACT: BIMI object
# VERSION
use 5.20.0;
use Moose;
use Moose::Util::TypeConstraints;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Record;
use Mail::BIMI::Result;
use Mail::DMARC::PurePerl;
  with(
    'Mail::BIMI::Role::Options',
    'Mail::BIMI::Role::Resolver',
    'Mail::BIMI::Role::Error',
  );

subtype 'MaybeDMARC'
  => as 'Any'
  => where {
    !defined $_
    || ref $_ eq 'Mail::DMARC::PurePerl'
    || ref $_ eq 'Mail::DMARC::Result'
  }
  => message {"dmarc_object Must be a Mail::DMARC::PurePerl, Mail::DMARC::Result, or Undefined"};

  has domain => ( is => 'rw', isa => Str, required => 0,
    documentation => 'inputs: Domain to lookup/domain record was retrieved from', );
  has selector => ( is => 'rw', isa => Str, lazy => 1, default => sub{ return 'default' },
    documentation => 'inputs: Selector to lookup/selector record was retrieved from', );
  has dmarc_object => ( is => 'rw', isa => 'MaybeDMARC',
    documentation => 'inputs: Validated Mail::DMARC::PurePerl object from parsed message', );
  has spf_object => ( is => 'rw', isa => 'Mail::SPF::Result',
    documentation => 'inputs: Mail::SPF::Result object from parsed message', );
  has dmarc_result_object => ( is => 'rw', isa => 'Maybe[Mail::DMARC::Result]', lazy => 1, builder => '_build_dmarc_result_object',
    documentation => 'Relevant Mail::DMARC::Result object' );
  has dmarc_pp_object => ( is => 'rw', isa => 'Maybe[Mail::DMARC::PurePerl]', lazy => 1, builder => '_build_dmarc_pp_object',
    documentation => 'Relevant Mail::DMARC::PurePerl object' );
  has record => ( is => 'rw', lazy => 1, builder => '_build_record',
    documentation => 'Mail::BIMI::Record object' );
  has result => ( is => 'rw', lazy => 1, builder => '_build_result',
    documentation => 'Mail::BIMI::Result object' );
  has time => ( is => 'ro', lazy => 1, default => sub{return time},
    documentation => 'time of retrieval - useful in testing' );

=head1 DESCRIPTION

Brand Indicators for Message Identification (BIMI) retrieval, validation, and processing

=head1 SYNOPSIS

  # Assuming we have a message, and have verified it has exactly one From Header domain, and passes
  # any other BIMI and local site requirements not related to BIMI record validation...
  # For example, relevant DKIM coverage of any BIMI-Selector header
  my $message = ...Specifics of adding headers and Authentication-Results is left to the reader...

  my $domain = "example.com"; # domain from From header
  my $selector = "default";   # selector from From header
  my $spf = Mail::SPF->new( ...See Mail::SPF POD for options... );
  my $dmarc = Mail::DMARC::PurePerl->new( ...See Mail::DMARC POD for options... );
  $dmarc->validate;

  my $bimi = Mail::BIMI->new(
    dmarc_object => $dmarc,
    spf_object => $spf,
    domain => $domain,
    selector => $selector,
  );

  my $auth_results = $bimi->get_authentication_results_object;
  my $bimi_result = $bimi->result;

  $message->add_auth_results($auth_results); # See Mail::AuthenticationResults POD for usage

  if ( $bimi_result->result eq 'pass' ) {
    my $headers = $result->headers;
    if ($headers) {
      $message->add_header( 'BIMI-Location', $headers->{'BIMI-Location'} if exists $headers->{'BIMI-Location'};
      $message->add_header( 'BIMI-Indicator', $headers->{'BIMI-Indicator'} if exists $headers->{'BIMI-Indicator'};
    }
  }

=cut

sub _build_dmarc_result_object($self) {
  return $self->dmarc_object->result if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  return $self->dmarc_object         if ref $self->dmarc_object eq 'Mail::DMARC::Result';
  return;
}

sub _build_dmarc_pp_object($self) {
  return $self->dmarc_object if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  warn 'Building our own Mail::DMARC::PurePerl object' if $self->OPT_VERBOSE;
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
      $result->set_result( 'skipped', $self->ERR_DMARC_NOT_PASS($self->dmarc_result_object->result));
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

  # Is Org DMARC Enforcing?
  my $org_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($self->domain);
  if ( lc $org_domain ne lc $self->domain ) {
    my $org_dmarc = Mail::DMARC::PurePerl->new;
    $org_dmarc->set_resolver($self->resolver);
    $org_dmarc->header_from($org_domain);
    $org_dmarc->validate;
    if (exists $org_dmarc->result->{published}){
      my $published_policy = $org_dmarc->result->published->p // '';
      my $published_subdomain_policy = $org_dmarc->result->published->sp // '';
      my $published_policy_pct = $org_dmarc->result->published->pct // 100;
      my $effective_published_policy = ( $org_dmarc->is_subdomain && $published_subdomain_policy ) ? lc $published_subdomain_policy : lc $published_policy;
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
  }

  # Optionally check Author Domain SPF
  if ( $self->OPT_STRICT_SPF ) {
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
  }

  if ( ! $self->record->is_valid ) {
    my $has_error;
    if ( ($has_error) = $self->record->filter_errors( 'NO_BIMI_RECORD' ) ) {
      $result->set_result( 'none', $has_error );
    }
    elsif ( ($has_error) = $self->record->filter_errors( 'DNS_ERROR' ) ) {
      $result->set_result( 'none', $has_error );
    }
    else {
      my @fail_errors = qw{
        NO_DMARC
        MULTI_BIMI_RECORD
        DUPLICATE_KEY
        EMPTY_L_TAG
        EMPTY_V_TAG
        INVALID_V_TAG
        MISSING_L_TAG
        MISSING_V_TAG
        MULTIPLE_AUTHORITIES
        MULTIPLE_LOCATIONS
        INVALID_TRANSPORT_A
        INVALID_TRANSPORT_L
        SPF_PLUS_ALL
        SVG_FETCH_ERROR
        VMC_FETCH_ERROR
        VMC_PARSE_ERROR
        VMC_VALIDATION_ERROR
        SVG_GET_ERROR
        SVG_SIZE
        SVG_UNZIP_ERROR
        SVG_INVALID_XML
        SVG_VALIDATION_ERROR
        SVG_MISMATCH
        VMC_REQUIRED
      };
      my $found_error = 0;

      foreach my $fail_error (@fail_errors) {
        if ( my ($error) = $self->record->filter_errors( $fail_error ) ) {
          $found_error = 1;
          $result->set_result( 'fail', $error );
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

  $result->set_result( 'pass' );

  return $result;
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->record->finish if $self->record;
}

=method I<app_validate()>

Output human readable validation status of this object

=cut

1;
