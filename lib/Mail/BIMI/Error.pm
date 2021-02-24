package Mail::BIMI::Error;
# ABSTRACT: Class to represent an error condition
# VERSION
use 5.20.0;
use Moose;
use Moose::Util::TypeConstraints;
use Mail::BIMI::Prelude;

my %ERROR_MAP = (
  BIMI_INVALID             => { description => 'Invalid BIMI Record' },
  BIMI_NOT_ENABLED         => { description => 'Domain is not BIMI enabled' },
  CODE_MISSING_AUTHORITY   => { description => 'No authority specified', result => 'temperror' },
  CODE_MISSING_LOCATION    => { description => 'No location specified', result => 'temperror'  },
  CODE_NOTHING_TO_VALIDATE => { description => 'Nothing To Validate', result => 'temperror'  },
  CODE_NO_DATA             => { description => 'No Data', result => 'temperror' },
  DMARC_NOT_ENFORCING      => { description => 'DMARC Policy is not at enforcement', result => 'skipped' },
  DMARC_NOT_PASS           => { description => 'DMARC did not pass', result => 'skipped' },
  DNS_ERROR                => { description => 'DNS query error', result => 'temperror' },
  DUPLICATE_KEY            => { description => 'Duplicate key in record' },
  EMPTY_L_TAG              => { description => 'Domain declined to participate', result => 'declined' },
  EMPTY_V_TAG              => { description => 'Empty v tag' },
  INVALID_TRANSPORT_A      => { description => 'Invalid transport in authority' },
  INVALID_TRANSPORT_L      => { description => 'Invalid transport in location' },
  INVALID_V_TAG            => { description => 'Invalid v tag' },
  MISSING_L_TAG            => { description => 'Missing l tag' },
  MISSING_V_TAG            => { description => 'Missing v tag' },
  MULTIPLE_AUTHORITIES     => { description => 'Multiple entries for a found' },
  MULTIPLE_LOCATIONS       => { description => 'Multiple entries for l found' },
  MULTI_BIMI_RECORD        => { description => 'Multiple BIMI records found' },
  NO_BIMI_RECORD           => { description => 'No BIMI records found', result => 'none' },
  NO_DMARC                 => { description => 'No DMARC', result => 'skipped' },
  SPF_PLUS_ALL             => { description => 'SPF +all detected', result => 'skipped' },
  SVG_FETCH_ERROR          => { description => 'Could not fetch SVG', result => 'temperror' },
  SVG_GET_ERROR            => { description => 'Could not fetch SVG', result => 'temperror' },
  SVG_INVALID_XML          => { description => 'Invalid XML in SVG' },
  SVG_MISMATCH             => { description => 'SVG in bimi-location did not match SVG in VMC' },
  SVG_SIZE                 => { description => 'SVG Document exceeds maximum size' },
  SVG_UNZIP_ERROR          => { description => 'Error unzipping SVG' },
  SVG_VALIDATION_ERROR     => { description => 'SVG did not validate' },
  VMC_EXPIRED              => { description => 'VMC has expired' },
  VMC_FETCH_ERROR          => { description => 'Could not fetch VMC', result => 'temperror' },
  VMC_PARSE_ERROR          => { description => 'Could not parse VMC' },
  VMC_REQUIRED             => { description => 'VMC is required' },
  VMC_VALIDATION_ERROR     => { description => 'VMC did not validate' },
);

has code => ( is => 'ro', isa => enum([sort keys %ERROR_MAP]), required => 1,
  documentation => 'inputs: Error code', );
has detail => ( is => 'ro', isa => 'Str', required => 0,
  documentation => 'inputs: Human readable details', );

=method I<description()>

Return the human readable description for this class of error

=cut

sub description($self) {
  return $ERROR_MAP{$self->code}->{description};
}

=method I<result()>

Return the Authentication-Results bimi= result for this class of error

=cut

sub result($self) {
  return exists $ERROR_MAP{$self->code}->{result} ? $ERROR_MAP{$self->code}->{result} : 'fail';
}

=head1 DESCRIPTION

Class for representing an error condition

=cut

1;
