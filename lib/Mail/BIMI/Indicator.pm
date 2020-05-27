package Mail::BIMI::Indicator;
# ABSTRACT: Class to model a BIMI indicator
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use IO::Uncompress::Gunzip;
use MIME::Base64;
use XML::LibXML;
our @VALIDATOR_PROFILES = qw{ SVG_1.2_BIMI SVG_1.2_PS Tiny-1.2 };
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::HTTPClient';
  with 'Mail::BIMI::Role::Data';
  with 'Mail::BIMI::Role::Cacheable';
  has location => ( is => 'rw', isa => Str, is_cache_key =>1  );
  has data => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data', is_cacheable => 1 );
  has data_uncompressed => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data_uncompressed', is_cacheable => 1 );
  has data_xml => ( is => 'rw', lazy => 1, builder => '_build_data_xml' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', is_cacheable => 1 );
  has parser => ( is => 'rw', lazy => 1, builder => '_build_parser' );
  has header => ( is => 'rw', lazy => 1, builder => '_build_header', is_cacheable => 1);
  has validator_profile => ( is => 'rw', isa => Enum[@VALIDATOR_PROFILES], lazy => 1, builder => '_build_validator_profile', is_cacheable => 1 );

sub _build_validator_profile($self) {
  return $self->bimi_object->OPT_SVG_PROFILE;
}

sub cache_valid_for($self) { return 3600 }
sub http_client_max_fetch_size($self) { return $self->bimi_object->OPT_SVG_MAX_FETCH_SIZE };

sub _build_data_uncompressed($self) {
  my $data = $self->data;
  if ( $data =~ /^\037\213/ ) {
    my $unzipped;
    eval{
      IO::Uncompress::Gunzip::gunzip(\$data,\$unzipped);
    };
    if ( my $error = $@ ) {
      $self->add_error( $self->ERR_SVG_UNZIP_ERROR );
      return;
    }
    return $unzipped;
  }
  else {
    return $data;
  }
}

sub data_maybe_compressed($self) {
  # Alias for clarity, the data is as received.
  return $self->data;
}

sub _build_data_xml($self) {
  my $xml;
  my $data = $self->data_uncompressed;
  if ( !$data ) {
    $self->add_error( $self->ERR_SVG_GET_ERROR );
    return;
  }
  eval {
    $xml = XML::LibXML->new->load_xml(string => $self->data_uncompressed);
  };
  if ( my $error = $@ ) {
    $self->add_error( $self->ERR_SVG_INVALID_XML );
    return;
  }
  return $xml;
}

{
  my $parser;
  sub _build_parser($self) {
    return $parser if $parser;
    $parser = XML::LibXML::RelaxNG->new( string => $self->get_data_from_file($self->validator_profile.'.rng'));
    return $parser;
  }
}

sub _build_data($self) {
  if ( ! $self->location ) {
    $self->add_error( $self->ERR_CODE_MISSING_LOCATION );
    return;
  }
  my $data = $self->http_client_get( $self->location );
  if ( !$self->http_client_response->{success} ) {
    if ( $self->http_client_response->{status} == 599 ) {
      $self->add_error({ error => $self->ERR_SVG_FETCH_ERROR, detail => $self->http_client_response->{content} });
    }
      else {
      $self->add_error({ error => $self->ERR_SVG_FETCH_ERROR, detail => $self->http_client_response->{status} });
    }
    return '';
  }
  return $data;
}

sub _build_is_valid($self) {

  if (!($self->data||$self->location)) {
    $self->add_error( $self->ERR_CODE_NOTHING_TO_VALIDATE );
    return 0;
  }

  if (!$self->data) {
    $self->add_error( $self->ERR_CODE_NO_DATA );
    return 0;
  }

  my $is_valid;

  if ( length $self->data_uncompressed > $self->bimi_object->OPT_SVG_MAX_SIZE ) {
    $self->add_error( $self->ERR_SVG_SIZE );
  }
  else {
    if ( $self->bimi_object->OPT_NO_VALIDATE_SVG ) {
      $is_valid=1;
    }
    else {
      eval {
        $self->parser->validate( $self->data_xml );
        $is_valid=1;
      };
      my $validation_errors = $@;
      if ( !$is_valid ) {
        $self->add_error({ error => $self->ERR_SVG_VALIDATION_ERROR, detail => $validation_errors });
      }
    }
  }

  return 0 if $self->error->@*;
  return 1;
}

sub _build_header($self) {
  return if !$self->is_valid;
  my $base64 = encode_base64( $self->data_uncompressed );
  $base64 =~ s/\n//g;
  my @parts = unpack("(A70)*", $base64);
  return join("\n    ", @parts);
}

sub app_validate($self) {
  say 'Indicator Returned:';
  say '  GZipped        : '.($self->data_uncompressed eq $self->data?'No':'Yes');
  say '  BIMI-Indicator : '.$self->header if $self->is_valid;
  say '  Profile Used   : '.$self->validator_profile;
  say '  Is Valid       : '.($self->is_valid?'Yes':'No');
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

