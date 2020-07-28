package Mail::BIMI::Indicator;
# ABSTRACT: Class to model a BIMI indicator
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Pragmas;
use IO::Uncompress::Gunzip;
use MIME::Base64;
use XML::LibXML;
our @VALIDATOR_PROFILES = qw{ SVG_1.2_BIMI SVG_1.2_PS Tiny-1.2 };
  with(
    'Mail::BIMI::Role::Base',
    'Mail::BIMI::Role::Error',
    'Mail::BIMI::Role::HTTPClient',
    'Mail::BIMI::Role::Data',
    'Mail::BIMI::Role::Cacheable',
  );
  has location => ( is => 'rw', isa => Str, traits => ['CacheKey'],
    documentation => 'inputs: URL to retrieve Indicator from', );
  has data => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data', traits => ['Cacheable'],
    documentation => 'inputs: Raw data representing the Indicator; Fetches from location if not given', );
  has data_uncompressed => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_data_uncompressed', traits => ['Cacheable'],
    documentation => 'Raw data in uncompressed form' );
  has data_xml => ( is => 'rw', lazy => 1, builder => '_build_data_xml',
    documentation => 'XML::LibXML object representing the Indicator' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', traits => ['Cacheable'],
    documentation => 'Is this indicator valid' );
  has parser => ( is => 'rw', lazy => 1, builder => '_build_parser',
    documentation => 'XML::LibXML::RelaxNG parser object used to validate the Indicator XML' );
  has header => ( is => 'rw', lazy => 1, builder => '_build_header', traits => ['Cacheable'],
    documentation => 'Indicator data encoded as Base64 ready for insertion as BIMI-Indicator header' );
  has validator_profile => ( is => 'rw', isa => Enum[@VALIDATOR_PROFILES], lazy => 1, builder => '_build_validator_profile', traits => ['Cacheable'],
    documentation => 'inputs: Validator profile used to validate the Indicator', );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a BIMI Indicator

=cut

sub _build_validator_profile($self) {
  return $self->bimi_object->OPT_SVG_PROFILE;
}

sub cache_valid_for($self) { return 3600 }
sub http_client_max_fetch_size($self) { return $self->bimi_object->OPT_SVG_MAX_FETCH_SIZE };

sub _build_data_uncompressed($self) {
  my $data = $self->data;
  if ( $data =~ /^\037\213/ ) {
    warn 'Uncompressing SVG' if $self->bimi_object->OPT_VERBOSE;
    my $unzipped;
    eval {
      IO::Uncompress::Gunzip::gunzip(\$data,\$unzipped);
      1;
    } || do {
      $self->add_error( $self->ERR_SVG_UNZIP_ERROR );
      return '';
    };
    if ( !$unzipped ) {
      $self->add_error( $self->ERR_SVG_UNZIP_ERROR );
      return '';
    }
    return $unzipped;
  }
  else {
    return $data;
  }
}

=method I<data_maybe_compressed()>

Synonym for data; returns the data in a maybe compressed format

=cut

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
    1;
  } || do {
    $self->add_error( $self->ERR_SVG_INVALID_XML );
    return;
  };
  return $xml;
}

sub _build_parser($self) {
  state $parser = XML::LibXML::RelaxNG->new( string => $self->get_data_from_file($self->validator_profile.'.rng'));
  return $parser;
}

sub _build_data($self) {
  if ( ! $self->location ) {
    $self->add_error( $self->ERR_CODE_MISSING_LOCATION );
    return '';
  }
  if ($self->bimi_object->OPT_SVG_FROM_FILE) {
    warn 'Reading SVG from file '.$self->bimi_object->OPT_SVG_FROM_FILE if $self->bimi_object->OPT_VERBOSE;
    return scalar read_file $self->bimi_object->OPT_SVG_FROM_FILE;
  }
  my $data = $self->http_client_get( $self->location );
  if ( !$self->http_client_response->{success} ) {
    if ( $self->http_client_response->{status} == 599 ) {
      $self->add_error($self->ERR_SVG_FETCH_ERROR($self->http_client_response->{content}));
    }
      else {
      $self->add_error($self->ERR_SVG_FETCH_ERROR($self->http_client_response->{status}));
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
      warn 'Skipping SVG validation' if $self->bimi_object->OPT_VERBOSE;
    }
    else {
      eval {
        $self->parser->validate( $self->data_xml );
        $is_valid=1;
        warn 'SVG is valid' if $self->bimi_object->OPT_VERBOSE;
        1;
      } || do {
        my $validation_error = $@;
        my $error_text = ref $validation_error eq 'XML::LibXML::Error' ? $validation_error->as_string : $validation_error;
        $self->add_error($self->ERR_SVG_VALIDATION_ERROR($error_text));
      };
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

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->_write_cache;
}

=method I<app_validate()>

Output human readable validation status of this object

=cut

sub app_validate($self) {
  say 'Indicator Returned:';
  say '  GZipped        : '.($self->data_uncompressed eq $self->data?'No':'Yes');
  say '  BIMI-Indicator : '.$self->header if $self->is_valid;
  say '  Profile Used   : '.$self->validator_profile;
  say '  Is Valid       : '.($self->is_valid?'Yes':'No');
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

