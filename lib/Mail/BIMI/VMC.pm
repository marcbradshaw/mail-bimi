package Mail::BIMI::VMC;
# ABSTRACT: Class to model a VMC
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
#use IO::Uncompress::Gunzip;
use MIME::Base64;
use Convert::ASN1;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify;
use Mozilla::CA;
use File::Temp qw{ tempfile };
use Mail::BIMI::Indicator;
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::Constants';
  with 'Mail::BIMI::Role::HTTPClient';
  with 'Mail::BIMI::Role::Data';
  with 'Mail::BIMI::Role::Cacheable';
  has authority => ( is => 'rw', isa => Str, is_cache_key =>1  );
  has data => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data', is_cacheable => 1 );
  has cert_list => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => '_build_cert_list', is_cacheable => 1 );
  has cert_object_list => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => '_build_cert_object_list', is_cacheable => 0 );
  has vmc_object => ( is => 'rw', lazy => 1, builder => '_build_vmc_object', is_cacheable => 0 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', is_cacheable => 1 );
  has is_cert_valid => ( is => 'rw', lazy => 1, builder => '_build_is_cert_valid', is_cacheable => 1 );
  has indicator_asn => ( is => 'rw', lazy => 1, builder => '_build_indicator_asn', is_cacheable => 0 );
  has indicator_uri => ( is => 'rw', lazt => 1, builder => '_build_indicator_uri', is_cacheable => 1 );
  has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator' );

sub cache_valid_for($self) { return 3600 }

sub _build_data($self) {
  if ( ! $self->authority ) {
    $self->add_error( $self->CODE_MISSING_AUTHORITY );
    return;
  }
  if ($self->bimi_object->VMC_FROM_FILE) {
    return scalar read_file $self->bimi_object->VMC_FROM_FILE;
  }
  my $data = $self->http_client_get( $self->authority );
  if ( !$self->http_client_response->{success} ) {
    if ( $self->http_client_response->{status} == 599 ) {
      $self->add_error({ error => $self->VMC_FETCH_ERROR, detail => $self->http_client_response->{content} });
    }
      else {
      $self->add_error({ error => $self->VMC_FETCH_ERROR, detail => $self->http_client_response->{status} });
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

sub _build_cert_object_list($self) {
  my @all_x509_certs;
  eval {
    @all_x509_certs = map { Crypt::OpenSSL::X509->new_from_string(join("\n",$_->@*)) } $self->cert_list->@*;
  };
  if ( my $error = $@ ) {
    $self->add_error({ error => $self->VMC_PARSE_ERROR, detail => $error });
  }
  return \@all_x509_certs;
}

sub _build_vmc_object($self) {
  return if !$self->cert_object_list->@*;
  return $self->cert_object_list->[0];
}

sub _build_is_cert_valid($self) {
  return 1 if $self->bimi_object->NO_VALIDATE_CERT;
  my $temp_fh = File::Temp->new(UNLINK=>0);
  my $temp_name = $temp_fh->filename;
  close $temp_fh;
  my $chain;
  my $cert_is_valid = 1;
  for (my  $i=scalar $self->cert_object_list->@* - 1;$i>=0;$i--) {
    my $ca = $chain
           ? Crypt::OpenSSL::Verify->new( CAfile => $temp_name)
           : Crypt::OpenSSL::Verify->new( CAfile => Mozilla::CA::SSL_ca_file);
    eval{$ca->verify($self->cert_object_list->[$i])};
    if ( my $error = $@ ) {
      $self->add_error({ error => $self->VMC_VALIDATION_ERROR, detail => $error });
      $cert_is_valid = 0;
      last;
    }

    $chain = join("\n",$self->cert_list->[$i]->@*);
    open $temp_fh, '>', $temp_name;
    print $temp_fh $chain;
    close $temp_fh;
  }
  unlink $temp_name;

  return $cert_is_valid;
}

sub subject($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->subject;
}

sub not_before($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->notBefore;
}

sub not_after($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->notAfter;
}

sub issuer($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->issuer;
}

sub is_expired($self) {
  return if !$self->vmc_object;
  my $seconds = 0;
  if ($self->vmc_object->checkend($seconds)) {
    return 1;
  }
  else {
    return 0;
  }
}

sub alt_name($self) {
  return if !$self->vmc_object;
  my $exts = $self->vmc_object->extensions_by_oid();
  my $alt_name = $exts->{'2.5.29.17'}->to_string;
  return $alt_name;
}

sub is_valid_alt_name($self) {
  return 1 if ! $self->authority_object; # Cannot check without context
  my $domain = lc $self->authority_object->record_object->domain;
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

sub is_self_signed($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->is_selfsigned;
}

sub has_valid_usage($self) {
  return if !$self->vmc_object;
  my $exts = $self->vmc_object->extensions_by_oid();
  my $extended_usage = $exts->{'2.5.29.37'}->to_string;
  return 1 if $extended_usage eq '1.3.6.1.5.5.7.3.31';
  return 0;
}

sub _build_indicator_asn($self) {
  return if !$self->vmc_object;
  my $exts = $self->vmc_object->extensions_by_oid();
  my $indhex = $exts->{'1.3.6.1.5.5.7.1.12'}->value;
  $indhex =~ s/^#//;
  my $indicator = pack("H*",$indhex);
  my $asn = Convert::ASN1->new;
  $asn->prepare_file($self->get_file_name('asn1.txt'));
  my $decoder = $asn->find('LogotypeExtn');
  die $asn->error if $asn->error;
  my $decoded = $decoder->decode($indicator);
  if ( $decoder->error ) {
    $self->add_error({ error => $self->VMC_PARSE_ERROR, detail => $decoder->error });
    return;
  }

  #my $image_details = $decoded->{subjectLogo}->{direct}->{image}->[0]->{imageDetails};
  #my $mime_type = $image_details->{mediaType};
  #my $logo_hash = $image_details->{logotypeHash}->[0];
  return $decoded;
}
 
sub _build_indicator_uri($self) {
  return if !$self->indicator_asn;
  my $uri = eval{ $self->indicator_asn->{subjectLogo}->{direct}->{image}->[0]->{imageDetails}->{logotypeURI}->[0] };
  if ( my $error = $@ ) {
    $self->add_error({ error => $self->VMC_PARSE_ERROR, detail => 'Could not extract SVG from VMC' });
  }
  return $uri;
}

sub _build_indicator($self) {
#  return if ! $self->_is_valid;
  return if !$self->is_cert_valid;
  my $uri = $self->indicator_uri;
  ## TODO MAKE THIS BETTER
  if ( $uri =~ /^data:image\/svg\+xml;base64,/ ) {
    my ( $null, $base64 ) = split( ',', $uri );
    my $data = MIME::Base64::decode($base64);
    return Mail::BIMI::Indicator->new( location => $self->indicator_uri, data => $data, bimi_object => $self->bimi_object );
  }
  else {
    $self->add_error({ error => $self->VMC_PARSE_ERROR, detail => 'Could not extract SVG from VMC' });
  }
}


sub _build_is_valid($self) {

  $self->add_error({ error => $self->VMC_VALIDATION_ERROR, detail => 'Expired' } ) if $self->is_expired;
  $self->add_error({ error => $self->VMC_VALIDATION_ERROR, detail => 'Missing usage flag' } ) if !$self->has_valid_usage;
  $self->add_error({ error => $self->VMC_VALIDATION_ERROR, detail => 'Invalid alt name' }) if !$self->is_valid_alt_name;
  $self->is_cert_valid;

  if ( !$self->indicator->is_valid ) {
    $self->add_error( $self->indicator->error );
  }

  return 0 if $self->error->@*;
  return 1;
}

sub app_validate($self) {
  say 'VMC Returned:';
  say '  Subject         : '.$self->subject;
  say '  Not Before      : '.$self->not_before;
  say '  Not After       : '.$self->not_after;
  say '  Issuer          : '.$self->issuer;
  say '  Expired         : '.( $self->is_expired ? 'Yes' : 'No' );
  say '  Alt Name        : '.$self->alt_name;
  say '  Alt Name Valid  : '.$self->is_valid_alt_name;
  say '  Has Valid Usage : '.( $self->has_valid_usage ? 'Yes' : 'No' );
  say '  Cert Valid      : '.( $self->is_cert_valid ? 'Yes' : 'No' );
  say '  Is Valid        : '.( $self->is_valid ? 'Yes' : 'No' );
  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->error_detail->@* ) {
      my $error_text = $error->{error};
      my $error_detail = $error->{detail};
      $error_detail =~ s/\n/\n    /g;
      say "  $error_text".($error_detail?"\n    ".$error_detail:'');
    }
  }
}

1;

