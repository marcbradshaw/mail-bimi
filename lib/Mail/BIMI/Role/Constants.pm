package Mail::BIMI::Role::Constants;
# ABSTRACT: Class to model defined constants
# VERSION
use 5.20.0;
use Moo::Role;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;

sub BIMI_INVALID             { return 'Invalid BIMI Record' }
sub BIMI_NOT_ENABLED         { return 'Domain is not BIMI enabled' }
sub CODE_MISSING_LOCATION    { return 'No location specified' }
sub CODE_NOTHING_TO_VALIDATE { return 'Nothing To Validate' }
sub CODE_NO_DATA             { return 'No Data' }
sub DNS_ERROR                { return 'DNS query error' }
sub DUPLICATE_KEY            { return 'Duplicate key in record' }
sub EMPTY_L_TAG              { return 'Empty l tag' }
sub EMPTY_V_TAG              { return 'Empty v tag' }
sub INVALID_TRANSPORT_A      { return 'Invalid transport in authority' }
sub INVALID_TRANSPORT_L      { return 'Invalid transport in location' }
sub INVALID_V_TAG            { return 'Invalid v tag' }
sub MISSING_L_TAG            { return 'Missing l tag' }
sub MISSING_V_TAG            { return 'Missing v tag' }
sub MULTIPLE_AUTHORITIES     { return 'Multiple entries for a found' }
sub MULTIPLE_LOCATIONS       { return 'Multiple entries for l found' }
sub MULTI_BIMI_RECORD        { return 'multiple BIMI records found' }
sub NO_BIMI_RECORD           { return 'no BIMI records found' }
sub NO_DMARC                 { return 'No DMARC' }
sub SPF_PLUS_ALL             { return 'SPF +all detected' }
sub SVG_FETCH_ERROR          { return 'Could not fetch SVG' }
sub SVG_GET_ERROR            { return 'Could not fetch SVG' }
sub SVG_INVALID_XML          { return 'Invalid XML in SVG' }
sub SVG_SIZE                 { return 'SVG Document exceeds maximum size' }
sub SVG_UNZIP_ERROR          { return 'Error unzipping SVG' }
sub SVG_VALIDATION_ERROR     { return 'SVG did not validate' }

1;
