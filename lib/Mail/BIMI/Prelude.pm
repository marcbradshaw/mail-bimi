package Mail::BIMI::Prelude;
# ABSTRACT: Setup system wide prelude
# VERSION
use 5.20.0;
use strict;
use warnings;
require feature;

=head1 DESCRIPTION

Distribution wide pragmas and imports

=cut

use open ':std', ':encoding(UTF-8)';
use Import::Into;
use Carp;
use File::Slurp;
use JSON;

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Carp->import::into(scalar caller);
  File::Slurp->import::into(scalar caller, qw{ read_file write_file } );
  JSON->import::into(scalar caller);
}

1;
