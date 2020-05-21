package Mail::BIMI::Role::Constants;
# ABSTRACT: Class to model defined constants
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;

sub ERR_BIMI_INVALID             { return 'Invalid BIMI Record' }
sub ERR_BIMI_NOT_ENABLED         { return 'Domain is not BIMI enabled' }
sub ERR_CODE_MISSING_AUTHORITY   { return 'No authority specified' }
sub ERR_CODE_MISSING_LOCATION    { return 'No location specified' }
sub ERR_CODE_NOTHING_TO_VALIDATE { return 'Nothing To Validate' }
sub ERR_CODE_NO_DATA             { return 'No Data' }
sub ERR_DMARC_NOT_ENFORCING      { return 'DMARC Policy is not at enforcement' }
sub ERR_DNS_ERROR                { return 'DNS query error' }
sub ERR_DUPLICATE_KEY            { return 'Duplicate key in record' }
sub ERR_EMPTY_L_TAG              { return 'Empty l tag' }
sub ERR_EMPTY_V_TAG              { return 'Empty v tag' }
sub ERR_INVALID_TRANSPORT_A      { return 'Invalid transport in authority' }
sub ERR_INVALID_TRANSPORT_L      { return 'Invalid transport in location' }
sub ERR_INVALID_V_TAG            { return 'Invalid v tag' }
sub ERR_MISSING_L_TAG            { return 'Missing l tag' }
sub ERR_MISSING_V_TAG            { return 'Missing v tag' }
sub ERR_MULTIPLE_AUTHORITIES     { return 'Multiple entries for a found' }
sub ERR_MULTIPLE_LOCATIONS       { return 'Multiple entries for l found' }
sub ERR_MULTI_BIMI_RECORD        { return 'Multiple BIMI records found' }
sub ERR_NO_BIMI_RECORD           { return 'No BIMI records found' }
sub ERR_NO_DMARC                 { return 'No DMARC' }
sub ERR_SPF_PLUS_ALL             { return 'SPF +all detected' }
sub ERR_SVG_FETCH_ERROR          { return 'Could not fetch SVG' }
sub ERR_SVG_GET_ERROR            { return 'Could not fetch SVG' }
sub ERR_SVG_INVALID_XML          { return 'Invalid XML in SVG' }
sub ERR_SVG_MISMATCH             { return 'SVG in bimi-location did not match SVG in VMC' }
sub ERR_SVG_SIZE                 { return 'SVG Document exceeds maximum size' }
sub ERR_SVG_UNZIP_ERROR          { return 'Error unzipping SVG' }
sub ERR_SVG_VALIDATION_ERROR     { return 'SVG did not validate' }
sub ERR_VMC_FETCH_ERROR          { return 'Could not fetch VMC' }
sub ERR_VMC_PARSE_ERROR          { return 'Could not parse VMC' }
sub ERR_VMC_REQUIRED             { return 'VMC is required' }
sub ERR_VMC_VALIDATION_ERROR     { return 'VMC did not validate' }

1;
