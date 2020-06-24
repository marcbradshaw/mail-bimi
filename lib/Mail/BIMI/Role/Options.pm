package Mail::BIMI::Role::Options;
# ABSTRACT: Shared options
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
use Mozilla::CA;

=head1 DESCRIPTION

Role for capturing caller options, which may be passed to the constructor, or set in environment

=cut

  has OPT_CACHE_BACKEND => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_CACHE_BACKEND}//$ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND}//'File'},
    documentation => 'Cache backend to use for cacheing' );
  has OPT_CACHE_FASTMMAP_SHARE_FILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_CACHE_FASTMMAP_SHARE_FILE}//'/tmp/mail-bimi.fastmmap'},
    documentation => 'Shared cache file when using FastMmap backend' );
  has OPT_CACHE_FILE_DIRECTORY => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_CACHE_FILE_DIRECTORY}//'/tmp/'},
    documentation => 'Directory to store Cache files in when using File backend' );
  has OPT_FORCE_RECORD => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_FORCE_RECORD}},
    documentation => 'Fake record to use' );
  has OPT_HTTP_CLIENT_TIMEOUT  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_HTTP_CLIENT_TIMEOUT}//3},
    documentation => 'Timeout value for HTTP' );
  has OPT_NO_LOCATION_WITH_VMC => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_LOCATION_WITH_VMC}},
    documentation => 'Do not check location if VMC was present' );
  has OPT_NO_VALIDATE_CERT => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_CERT}},
    documentation => 'Do not validate VMC' );
  has OPT_NO_VALIDATE_SVG => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_SVG}},
    documentation => 'Do not validate SVG' );
  has OPT_REQUIRE_VMC => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_REQUIRE_VMC}},
    documentation => 'Require VMC validation' );
  has OPT_SSL_ROOT_CERT => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SSL_ROOT_CERT}//Mozilla::CA::SSL_ca_file},
    documentation => 'Location of SSL Root Cert Bundle' );
  has OPT_STRICT_SPF => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_STRICT_SPF}},
    documentation => 'Disallow SPF +all' );
  has OPT_SVG_FROM_FILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_FROM_FILE}},
    documentation => 'Fake SVG with file contents' );
  has OPT_SVG_MAX_FETCH_SIZE  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_MAX_FETCH_SIZE}//65535},
    documentation => 'Maximum fetch size for SVG retrieval' );
  has OPT_SVG_MAX_SIZE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_MAX_SIZE}//32768},
    documentation => 'Maximum valid size for SVG' );
  has OPT_SVG_PROFILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_SVG_PROFILE}//'SVG_1.2_PS'},
    documentation => 'Profile name to use for SVG validation' );
  has OPT_VERBOSE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VERBOSE}},
    documentation => 'Be More Verbose' );
  has OPT_VMC_FROM_FILE => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VMC_FROM_FILE}},
    documentation => 'Fake VMC with file contents' );
  has OPT_VMC_MAX_FETCH_SIZE  => ( is => 'rw', lazy => 1, builder => sub {return $ENV{MAIL_BIMI_VMC_MAX_FETCH_SIZE}//65535},
    documentation => 'Maximum fetch size for VMC retrieval' );

1;
