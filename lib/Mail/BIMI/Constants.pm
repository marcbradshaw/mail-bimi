package Mail::BIMI::Constants;
# ABSTRACT: Setup system wide constants
# VERSION
use 5.20.0;
use strict;
use warnings;
use parent 'Exporter';

use constant LOGOTYPE_OID          => '1.3.6.1.5.5.7.1.12';
use constant USAGE_OID             => '1.3.6.1.5.5.7.3.31';
use constant IS_EXPERIMENTAL_OID   => '1.3.6.1.4.1.53087.4.1';
use constant SUBJECT_MARK_TYPE_OID => '1.3.6.1.4.1.53087.1.13';

our @EXPORT = qw( LOGOTYPE_OID USAGE_OID IS_EXPERIMENTAL_OID SUBJECT_MARK_TYPE_OID );
our @EXPORT_OK = ( @EXPORT );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

1;
