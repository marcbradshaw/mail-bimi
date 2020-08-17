package Mail::BIMI::Error;
# ABSTRACT: Class to represent an error condition
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

my %DESCRIPTIONS_MAP = (
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
);

has code => ( is => 'ro', isa => Enum[sort keys %DESCRIPTIONS_MAP], required => 1,
  documentation => 'inputs: Error code', );
has detail => ( is => 'ro', isa => Str, required => 0,
  documentation => 'inputs: Human readable details', );

sub description($self) {
  return $DESCRIPTIONS_MAP{$self->code};
}

=head1 DESCRIPTION

Class for representing an error condition

=cut

1;
