package Mail::BIMI::Role::Options;
# ABSTRACT: Shared options
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  has CACHE_BACKEND => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_CACHE_BACKEND}} );
  has FORCE_RECORD => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_FORCE_RECORD}});
  has NO_LOCATION_WITH_VMC => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_LOCATION_WITH_VMC}} );
  has NO_VALIDATE_CERT => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_CERT}} );
  has NO_VALIDATE_SVG => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_SVG}} );
  has SVG_PROFILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_PROFILE}} );
  has VMC_FROM_FILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VMC_FROM_FILE}} );

1;
