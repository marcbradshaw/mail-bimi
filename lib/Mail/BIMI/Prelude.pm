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
use English;
use File::Slurp;
use JSON;
use Types::Standard qw{Str HashRef ArrayRef Enum Undef};

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Carp->import::into(scalar caller);
  English->import::into(scalar caller);
  File::Slurp->import::into(scalar caller, qw{ read_file write_file } );
  JSON->import::into(scalar caller);
  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum Undef} );
}

1;
