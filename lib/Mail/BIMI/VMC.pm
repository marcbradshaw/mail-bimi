package Mail::BIMI::VMC;
# ABSTRACT: Class to model a VMC
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use MIME::Base64;
use Mail::BIMI::Indicator;
use Mail::BIMI::VMC::Chain;
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::HTTPClient';
  with 'Mail::BIMI::Role::Cacheable';
  has authority => ( is => 'rw', isa => Str, is_cache_key => 1,
    documentation => 'URI of this VMC', pod_section => 'inputs' );
  has data => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data', is_cacheable => 1,
    documentation => 'Raw data of the VMC contents; Fetched from authority URI if not given', pod_section => 'inputs' );
  has cert_list => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => '_build_cert_list', is_cacheable => 1,
    documentation => 'ArrayRef of individual Certificates in the chain' );
  has chain_object => ( is => 'rw', lazy => 1, builder => '_build_chain_object', is_cacheable => 0,
    documentation => 'Mail::BIMI::VMC::Chain object for this Chain' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', is_cacheable => 1,
    documentation => 'Is this VMC valid' );
  has vmc_object => ( is => 'rw', lazy => 1, builder => '_build_vmc_object', is_cacheable => 0,
    documentation => 'Mail::BIMI::VMC::Cert object for this VMC Set' );
  has is_cert_valid => ( is => 'rw', lazy => 1, builder => '_build_is_cert_valid', is_cacheable => 1,
    documentation => 'Is this Certificate Set valid' );
  has indicator_uri => ( is => 'rw', lazt => 1, builder => '_build_indicator_uri', is_cacheable => 1,
    documentation => 'The URI of the embedded Indicator' );
  has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
    documentation => 'Mail::BIMI::Indicator object for the Indicator embedded in this VMC Set' );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Set

=cut

sub cache_valid_for($self) { return 3600 }
sub http_client_max_fetch_size($self) { return $self->bimi_object->OPT_VMC_MAX_FETCH_SIZE };

sub _build_data($self) {
  if ( ! $self->authority ) {
    $self->add_error( $self->ERR_CODE_MISSING_AUTHORITY );
    return;
  }
  if ($self->bimi_object->OPT_VMC_FROM_FILE) {
    return scalar read_file $self->bimi_object->OPT_VMC_FROM_FILE;
  }
  my $data = $self->http_client_get( $self->authority );
  if ( !$self->http_client_response->{success} ) {
    if ( $self->http_client_response->{status} == 599 ) {
      $self->add_error($self->ERR_VMC_FETCH_ERROR($self->http_client_response->{content}));
    }
      else {
      $self->add_error($self->ERR_VMC_FETCH_ERROR($self->http_client_response->{status}));
    }
    return '';
  }
  return $data;
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
  return 1 if $self->bimi_object->OPT_NO_VALIDATE_CERT;
  return $self->chain_object->is_valid;
}

=method I<subject()>

Return the subject of the VMC

=cut

sub subject($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->object->subject;
}

=method I<not_before()>

Return not before of the vmc

=cut

sub not_before($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->object->notBefore;
}

=method I<not_after()>

Return not after of the vmc

=cut

sub not_after($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->object->notAfter;
}

=method I<issuer()>

Return the issuer string of the VMC

=cut

sub issuer($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->object->issuer;
}

=method I<is_expired()>

Return true if this VMC has expired

=cut

sub is_expired($self) {
  return if !$self->vmc_object;
  my $seconds = 0;
  if ($self->vmc_object->object->checkend($seconds)) {
    warn 'Cert is expired' if $self->bimi_object->OPT_VERBOSE;
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
  my $exts = eval{ $self->vmc_object->object->extensions_by_oid() };
  return if !$exts;
  return if !exists $exts->{'2.5.29.17'};
  my $alt_name = $exts->{'2.5.29.17'}->to_string;
  warn 'Cert alt name '.$alt_name if $self->bimi_object->OPT_VERBOSE;
  return $alt_name;
}

=method I<is_valid_alt_name()>

Return true if the VMC has a valid alt name for the domain of the current operation

=cut

sub is_valid_alt_name($self) {
  return 1 if ! $self->authority_object; # Cannot check without context
  my $domain = lc $self->authority_object->record_object->domain;
  return 0 if !$self->alt_name;
  my @alt_names = split( ',', lc $self->alt_name );
  foreach my $alt_name ( @alt_names ) {
    $alt_name =~ s/^\s+//;
    $alt_name =~ s/\s+$//;
    next if ! $alt_name =~ /^dns:/;
    $alt_name =~ s/^dns://;
    return 1 if $alt_name eq $domain;
  }
  return 0;
}

=method I<is_self_signed()>

Return true if this VMC is self signed

=cut

sub is_self_signed($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->object->is_selfsigned ? 1 : 0;
}

=method I<has_valid_usage()>

Return true if this VMC has a valid usage extension for BIMI

=cut

sub has_valid_usage($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->has_valid_usage;
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
    $self->add_error($self->ERR_VMC_PARSE_ERROR('Could not extract SVG from VMC'));
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
    return Mail::BIMI::Indicator->new( location => $self->indicator_uri, data => $data, bimi_object => $self->bimi_object );
  }
  else {
    $self->add_error($self->ERR_VMC_PARSE_ERROR('Could not extract SVG from VMC'));
    return;
  }
}


sub _build_is_valid($self) {

  $self->add_error($self->ERR_VMC_VALIDATION_ERROR('Expired')) if $self->is_expired;
  $self->add_error($self->ERR_VMC_VALIDATION_ERROR('Missing usage flag')) if !$self->has_valid_usage;
  $self->add_error($self->ERR_VMC_VALIDATION_ERROR('Invalid alt name')) if !$self->is_valid_alt_name;
  $self->is_cert_valid;

  if ( $self->chain_object && !$self->chain_object->is_valid ) {
    $self->add_error( $self->chain_object->error );
  }

  if ( $self->indicator && !$self->indicator->is_valid ) {
    $self->add_error( $self->indicator->error );
  }

  return 0 if $self->error->@*;
  warn 'VMC is valid' if $self->bimi_object->OPT_VERBOSE;
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
  say 'VMC Returned:';
  say '  Subject         : '.($self->subject//'-none-');
  say '  Not Before      : '.($self->not_before//'-none-');
  say '  Not After       : '.($self->not_after//'-none-');
  say '  Issuer          : '.($self->issuer//'-none-');
  say '  Expired         : '.($self->is_expired ? 'Yes' : 'No' );
  say '  Alt Name        : '.($self->alt_name//'-none-');
  say '  Alt Name Valid  : '.($self->is_valid_alt_name?'Yes':'No');
  say '  Has Valid Usage : '.($self->has_valid_usage?'Yes':'No');
  say '  Cert Valid      : '.($self->is_cert_valid?'Yes':'No');
  say '  Is Valid        : '.($self->is_valid?'Yes':'No');
  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->error->@* ) {
      my $error_code = $error->code;
      my $error_text = $error->description;
      my $error_detail = $error->detail // '';
      $error_detail =~ s/\n/\n    /g;
      say "  $error_code : $error_text".($error_detail?"\n    ".$error_detail:'');
    }
  }
}

1;

