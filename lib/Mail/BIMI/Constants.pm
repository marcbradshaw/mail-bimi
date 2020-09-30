package Mail::BIMI::Constants;
# ABSTRACT: Setup system wide constants
# VERSION
use 5.20.0;
use strict;
use warnings;
use base 'Exporter';

use constant LOGOTYPE_OID => '1.3.6.1.5.5.7.1.12';
use constant USAGE_OID    => '1.3.6.1.5.5.7.3.31';

our @EXPORT = qw( LOGOTYPE_OID USAGE_OID );
our @EXPORT_OK = ( @EXPORT );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

1;
