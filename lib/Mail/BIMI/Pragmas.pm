package Mail::BIMI::Pragmas;
# ABSTRACT: Setup system wide pragmas
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
use MooX::Types::MooseLike::Base qw{AnyOf};
use Type::Utils qw{class_type};
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
  MooX::Types::MooseLike::Base->import::into(scalar caller, qw{AnyOf} );
  Type::Utils->import::into(scalar caller, qw{ class_type } );
  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum Undef} );
}

1;
