package Mail::BIMI::Pragmas;
# ABSTRACT: Setup system wide pragmas
# VERSION
use 5.20.0;
use strict;
use warnings;
require feature;

use open ':std', ':encoding(UTF-8)';
use Import::Into;
use Carp;
use English;
use File::Slurp;
use JSON;
use Type::Utils qw{class_type};
use Types::Standard qw{Str HashRef ArrayRef Enum};

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Carp->import::into(scalar caller);
  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum } );
  Type::Utils->import::into(scalar caller, qw{ class_type } );
  English->import::into(scalar caller);
  File::Slurp->import::into(scalar caller, qw{ read_file write_file } );
  JSON->import::into(scalar caller);
}

1;
