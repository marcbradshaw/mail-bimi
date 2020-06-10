package Mail::BIMI::Role::Error;
# ABSTRACT: Class to model an error
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Error;
  has error => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => sub{return []}, is_cacheable => 1 );

=head1 DESCRIPTION

Role for handling validation errors

=cut

{
  my $error_hash = {
    BIMI_INVALID             => 'Invalid BIMI Record',
    BIMI_NOT_ENABLED         => 'Domain is not BIMI enabled',
    CODE_MISSING_AUTHORITY   => 'No authority specified',
    CODE_MISSING_LOCATION    => 'No location specified',
    CODE_NOTHING_TO_VALIDATE => 'Nothing To Validate',
    CODE_NO_DATA             => 'No Data',
    DMARC_NOT_ENFORCING      => 'DMARC Policy is not at enforcement',
    DMARC_NOT_PASS           => 'DMARC did not pass',
    DNS_ERROR                => 'DNS query error',
    DUPLICATE_KEY            => 'Duplicate key in record',
    EMPTY_L_TAG              => 'Empty l tag',
    EMPTY_V_TAG              => 'Empty v tag',
    INVALID_TRANSPORT_A      => 'Invalid transport in authority',
    INVALID_TRANSPORT_L      => 'Invalid transport in location',
    INVALID_V_TAG            => 'Invalid v tag',
    MISSING_L_TAG            => 'Missing l tag',
    MISSING_V_TAG            => 'Missing v tag',
    MULTIPLE_AUTHORITIES     => 'Multiple entries for a found',
    MULTIPLE_LOCATIONS       => 'Multiple entries for l found',
    MULTI_BIMI_RECORD        => 'Multiple BIMI records found',
    NO_BIMI_RECORD           => 'No BIMI records found',
    NO_DMARC                 => 'No DMARC',
    SPF_PLUS_ALL             => 'SPF +all detected',
    SVG_FETCH_ERROR          => 'Could not fetch SVG',
    SVG_GET_ERROR            => 'Could not fetch SVG',
    SVG_INVALID_XML          => 'Invalid XML in SVG',
    SVG_MISMATCH             => 'SVG in bimi-location did not match SVG in VMC',
    SVG_SIZE                 => 'SVG Document exceeds maximum size',
    SVG_UNZIP_ERROR          => 'Error unzipping SVG',
    SVG_VALIDATION_ERROR     => 'SVG did not validate',
    VMC_FETCH_ERROR          => 'Could not fetch VMC',
    VMC_PARSE_ERROR          => 'Could not parse VMC',
    VMC_REQUIRED             => 'VMC is required',
    VMC_VALIDATION_ERROR     => 'VMC did not validate',
  };

  no strict 'refs';
  foreach my $error ( sort keys $error_hash->%* ) {
    my $method_name = 'ERR_'.$error;
    *$method_name = sub{
      my ( $self, $detail ) = @_;
      return Mail::BIMI::Error->new(
        code => $error,
        description => $error_hash->{$error},
        $detail ? ( detail => $detail ) : (),
      );
    };
  }
}


=method I<add_error($error)>

Add an error, or errors, to the current operation

=cut

sub add_error($self,$error) {
if ( ref $error eq 'ARRAY' ) {
    foreach my $suberror ( $error->@* ){
        $self->add_error($suberror);
    }
  }
  else {
    warn join(' : ',
      'Error',
      $error->code,
      $error->description
      ( $error->detail ? $error->detail : () ),
    ) if $self->bimi_object->OPT_VERBOSE;
    push $self->error->@*, $error;
  }
}

=method I<error_codes>

Return an ArrayRef of current error codes

=cut

sub error_codes($self) {
  my @error_codes = map { $_->code } $self->error->@*;
  return \@error_codes;
}

=method I<filter_errors($error)>

Return error(s) matching the given error code

=cut

sub filter_errors($self,$error) {
  return grep { $_->code eq $error } $self->error->@*;
}

1;
