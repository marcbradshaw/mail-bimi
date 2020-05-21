package Mail::BIMI::Role::Options;
# ABSTRACT: Shared options
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
use Mozilla::CA;
  has CACHE_BACKEND => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_CACHE_BACKEND}} );

  has FORCE_RECORD => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_FORCE_RECORD}});
  has HTTP_CLIENT_TIMEOUT  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_HTTP_CLIENT_TIMEOUT}//3} );
  has NO_LOCATION_WITH_VMC => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_LOCATION_WITH_VMC}} );
  has NO_VALIDATE_CERT => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_CERT}} );
  has NO_VALIDATE_SVG => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_SVG}} );
  has SSL_ROOT_CERT => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SSL_ROOT_CERT}}//Mozilla::CA::SSL_ca_file );
  has SVG_MAX_FETCH_SIZE  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_MAX_FETCH_SIZE}//65535} );
  has SVG_MAX_SIZE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_MAX_SIZE}//32768} );
  has SVG_PROFILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_PROFILE}//'SVG_1.2_PS'} );
  has VMC_FROM_FILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VMC_FROM_FILE}} );
  has VMC_MAX_FETCH_SIZE  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VMC_MAX_FETCH_SIZE}//65535} );

1;
