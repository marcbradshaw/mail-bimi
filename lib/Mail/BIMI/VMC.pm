package Mail::BIMI::VMC;
# ABSTRACT: Class to model a VMC
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use File::Slurp qw{ read_file write_file };
use MIME::Base64;
use Term::ANSIColor qw{ :constants };
use Mail::BIMI::Indicator;
use Mail::BIMI::VMC::Chain;

extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::HasError',
  'Mail::BIMI::Role::HasHTTPClient',
  'Mail::BIMI::Role::Cacheable',
);
has uri => ( is => 'rw', isa => 'Str', traits => ['CacheKey'],
  documentation => 'inputs: URI of this VMC', );
has check_domain => ( is => 'ro', isa => 'Str', required => 1, traits => ['CacheKey'],
  documentation => 'inputs: Domain to check the alt_name against', );
has check_selector => ( is => 'ro', isa => 'Str', required => 1, traits => ['CacheKey'],
  documentation => 'inputs: Selector to check the alt_name against', );
has data => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build_data', traits => ['Cacheable'],
  documentation => 'inputs: Raw data of the VMC contents; Fetched from authority URI if not given', );
has cert_list => ( is => 'rw', isa => 'ArrayRef', lazy => 1, builder => '_build_cert_list', traits => ['Cacheable'],
  documentation => 'ArrayRef of individual Certificates in the chain' );
has chain_object => ( is => 'rw', lazy => 1, builder => '_build_chain_object',
  documentation => 'Mail::BIMI::VMC::Chain object for this Chain' );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', traits => ['Cacheable'],
  documentation => 'Is this VMC valid' );
has vmc_object => ( is => 'rw', lazy => 1, builder => '_build_vmc_object',
  documentation => 'Mail::BIMI::VMC::Cert object for this VMC Set' );
has is_cert_valid => ( is => 'rw', lazy => 1, builder => '_build_is_cert_valid', traits => ['Cacheable'],
  documentation => 'Is this Certificate Set valid' );
has indicator_uri => ( is => 'rw', lazy => 1, builder => '_build_indicator_uri', traits => ['Cacheable'],
  documentation => 'The URI of the embedded Indicator' );
has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
  documentation => 'Mail::BIMI::Indicator object for the Indicator embedded in this VMC Set' );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Set

=cut

=method I<cache_valid_for()>

How long should the cache for this class be valid

=cut

sub cache_valid_for($self) { return 3600 }

=method I<http_client_max_fetch_size()>

Maximum permitted HTTP fetch

=cut

sub http_client_max_fetch_size($self) { return $self->bimi_object->options->vmc_max_fetch_size };

sub _build_data($self) {
  if ( ! $self->uri ) {
    $self->add_error('CODE_MISSING_AUTHORITY');
    return '';
  }
  if ($self->bimi_object->options->vmc_from_file) {
    return scalar read_file $self->bimi_object->options->vmc_from_file;
  }

  $self->log_verbose('HTTP Fetch: '.$self->uri);
  my $response = $self->http_client_get( $self->uri );
  if ( !$response->{success} ) {
    if ( $response->{status} == 599 ) {
      $self->add_error('VMC_FETCH_ERROR',$response->{content});
    }
    else {
      $self->add_error('VMC_FETCH_ERROR',$response->{status});
    }
    return '';
  }
  return $response->{content};
}

sub _build_cert_list($self) {
  my @certs;
  my $this_cert = [];
  my $data = $self->data;
  foreach my $cert_line ( split(/\n/,$data) ) {
    $cert_line =~ s/\r//;
    next if ! $cert_line;
    push $this_cert->@*, $cert_line;
    if ( $cert_line =~ /^\-+END CERTIFICATE\-+$/ ) {
        push @certs, $this_cert if $this_cert->@*;
        $this_cert = [];
    }
  }
  push @certs, $this_cert if $this_cert->@*;
  return \@certs;
}


sub _build_chain_object($self) {
  return Mail::BIMI::VMC::Chain->new( bimi_object => $self->bimi_object, cert_list => $self->cert_list );
}


sub _build_vmc_object($self) {
  return if !$self->chain_object;
  return if !$self->chain_object->vmc;
  return $self->chain_object->vmc;
}

sub _build_is_cert_valid($self) {
  return 1 if $self->bimi_object->options->no_validate_cert;
  return $self->chain_object->is_valid;
}

=method I<subject()>

Return the subject of the VMC

=cut

sub subject($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->subject;
}

=method I<mark_type()>

Return the subject:markType if available

=cut

sub mark_type($self) {
  return unless $self->vmc_object;

  # Parse the subject:markType from the subject string
  # Ideally we could parse the structure, from this
  # my $subject_entries = $self->vmc_object->x509_object->subject_name->entries;
  # however the X509 object does not make this easy for a type that is not
  # compiled in, returning undef for an entry type it does not understand.
  # So we parse the string instead.

  my $subject = $self->subject;
  return unless $subject;

  my @subject_entries = split /, ?/, $subject;
  for my $subject_entry (@subject_entries) {
    my ($key, $value) = split /= ?/, $subject_entry, 2;
    next unless $key eq SUBJECT_MARK_TYPE_OID || $key eq 'markType';
    return $value;
  }
  return;
}

=method I<not_before()>

Return not before of the vmc

=cut

sub not_before($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->notBefore;
}

=method I<not_after()>

Return not after of the vmc

=cut

sub not_after($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->notAfter;
}

=method I<issuer()>

Return the issuer string of the VMC

=cut

sub issuer($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->issuer;
}

=method I<is_expired()>

Return true if this VMC has expired

=cut

sub is_expired($self) {
  return if !$self->vmc_object;
  my $seconds = 0;
  if ($self->vmc_object->x509_object->checkend($seconds)) {
    $self->log_verbose('Cert is expired');
    return 1;
  }
  else {
    return 0;
  }
}

=method I<alt_name()>

Return the alt name string for the VMC

=cut

sub alt_name($self) {
  return if !$self->vmc_object;
  my $exts = eval{ $self->vmc_object->x509_object->extensions_by_oid() };
  return if !$exts;
  return if !exists $exts->{'2.5.29.17'};
  my $alt_name = $exts->{'2.5.29.17'}->to_string;
  $self->log_verbose('Cert alt name '.$alt_name);
  return $alt_name;
}

=method I<is_valid_alt_name()>

Return true if the VMC has a valid alt name for the domain of the current operation

=cut

sub is_valid_alt_name($self) {
  return 1 if !$self->check_domain; # Nothing to check against, default to allow
  return 1 if $self->bimi_object->options->vmc_no_check_alt;
  return 0 if !$self->alt_name;
  my @alt_names = split( ',', lc $self->alt_name );
  my $check_full_record = lc join('.', $self->check_selector, '_bimi', $self->check_domain );
  my $check_domain = lc $self->check_domain;
  foreach my $alt_name ( @alt_names ) {
    $alt_name =~ s/^\s+//;
    $alt_name =~ s/\s+$//;
    next if ! $alt_name =~ /^dns:/;
    $alt_name =~ s/^dns://;
    return 1 if $alt_name eq $check_domain;
    return 1 if $alt_name eq $check_full_record;
    next if !$self->bimi_object->options->cert_subdomain_is_valid;
    my $alt_name_re = quotemeta($alt_name);
    return 1 if $check_domain =~ /\.$alt_name_re$/;
  }
  return 0;
}

=method I<is_self_signed()>

Return true if this VMC is self signed

=cut

sub is_self_signed($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->is_selfsigned ? 1 : 0;
}

=method I<has_valid_usage()>

Return true if this VMC has a valid usage extension for BIMI

=cut

sub has_valid_usage($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->has_valid_usage;
}

=method I<is_experimental()>

Return true if this (V)MC is experimental

=cut

sub is_experimental($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->is_experimental;
}

=method I<is_allowed_mark_type()>

=cut

sub is_allowed_mark_type($self) {
  my $mark_type = lc ($self->mark_type // '');
  my $allowed_mark_types = lc $self->bimi_object->options->allowed_mark_types;
  for my $allowed_mark_type (split /, ?/, $allowed_mark_types) {
    return 1 if $allowed_mark_type eq '*';
    return 1 if $allowed_mark_type eq $mark_type;
  }
  return 0;
}

sub _build_indicator_uri($self) {
  return if !$self->vmc_object;
  return if !$self->vmc_object->indicator_asn;
  my $uri;
  eval{
    $uri = $self->vmc_object->indicator_asn->{subjectLogo}->{direct}->{image}->[0]->{imageDetails}->{logotypeURI}->[0];
    1;
  } || do {
    my $error = $@;
    $self->add_error('VMC_PARSE_ERROR','Could not extract SVG from VMC');
  };
  return $uri;
}

sub _build_indicator($self) {
#  return if ! $self->_is_valid;
  return if !$self->is_cert_valid;
  my $uri = $self->indicator_uri;
  return if !$uri;
  ## TODO MAKE THIS BETTER
  if ( $uri =~ /^data:image\/svg\+xml;base64,/ ) {
    my ( $null, $base64 ) = split( ',', $uri );
    my $data = MIME::Base64::decode($base64);
    return Mail::BIMI::Indicator->new( uri => $self->uri, data => $data, bimi_object => $self->bimi_object, source => 'VMC' );
  }
  else {
    $self->add_error('VMC_PARSE_ERROR','Could not extract SVG from VMC');
    return;
  }
}


sub _build_is_valid($self) {

  if ($self->data eq '' && $self->errors->@*) {
    # We already have a fetch error, do not validate further
    return 0;
  }

  $self->add_error('VMC_EXPIRED','Expired') if $self->is_expired;
  $self->add_error('VMC_VALIDATION_ERROR','Missing usage flag') if !$self->has_valid_usage;
  $self->add_error('VMC_VALIDATION_ERROR','Invalid alt name') if !$self->is_valid_alt_name;
  $self->add_error('VMC_DISALLOWED_TYPE', 'VMC Mark Type not supported here' ) if !$self->is_allowed_mark_type;
  $self->is_cert_valid;

  if ( $self->chain_object && !$self->chain_object->is_valid ) {
    $self->add_error_object( $self->chain_object->errors );
  }

  if ( $self->indicator && !$self->indicator->is_valid ) {
    $self->add_error_object( $self->indicator->errors );
  }

  if ( $self->bimi_object->options->no_experimental_vmc && $self->is_experimental ) {
    $self->add_error('VMC_NO_EXPERIMENTAL','Experimental (V)MCs are not accepted here');
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('VMC is valid');
  return 1;
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->indicator->finish if $self->indicator;
  $self->_write_cache;
}

=method I<app_validate()>

Output human readable validation status of this object

=cut

sub app_validate($self) {
  say 'VMC Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  say YELLOW.'  Subject         '.WHITE.': '.CYAN.($self->subject//'-none-').RESET;
  say YELLOW.'  Mark Type       '.WHITE.': '.CYAN.($self->mark_type//'-none-').RESET;
  say YELLOW.'  Is Allowed Type '.WHITE.': '.CYAN.($self->is_allowed_mark_type?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Not Before      '.WHITE.': '.CYAN.($self->not_before//'-none-').RESET;
  say YELLOW.'  Not After       '.WHITE.': '.CYAN.($self->not_after//'-none-').RESET;
  say YELLOW.'  Issuer          '.WHITE.': '.CYAN.($self->issuer//'-none-').RESET;
  say YELLOW.'  Expired         '.WHITE.': '.($self->is_expired?BRIGHT_RED.'Yes':GREEN.'No').RESET;
  say YELLOW.'  Alt Name        '.WHITE.': '.CYAN.($self->alt_name//'-none-').RESET;
  say YELLOW.'  Alt Name Valid  '.WHITE.': '.CYAN.($self->is_valid_alt_name?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Has Valid Usage '.WHITE.': '.CYAN.($self->has_valid_usage?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Cert Valid      '.WHITE.': '.CYAN.($self->is_cert_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Is Valid        '.WHITE.': '.CYAN.($self->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->errors->@* ) {
      my $error_code = $error->code;
      my $error_text = $error->description;
      my $error_detail = $error->detail // '';
      $error_detail =~ s/\n/\n    /g;
      say BRIGHT_RED."  $error_code ".WHITE.': '.CYAN.$error_text.($error_detail?"\n    ".$error_detail:'').RESET;
    }
  }
  if ($self->chain_object){
    say '';
    $self->chain_object->app_validate;
  }
}

1;

