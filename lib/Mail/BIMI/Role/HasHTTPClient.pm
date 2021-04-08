package Mail::BIMI::Role::HasHTTPClient;
# ABSTRACT: Class to model a HTTP client
# VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use HTTP::Tiny::Paranoid;

has http_client => ( is => 'rw', lazy => 1, builder => '_build_http_client',
  documentation => 'HTTP::Tiny::Paranoid (or similar) object used for HTTP operations' );
requires 'http_client_max_fetch_size';

=head1 DESCRIPTION

Role for classes which require a HTTP Client implementation

=cut

{
  my $http_client;
  sub _build_http_client($self) {
    return $http_client if $http_client;
    my $agent = 'Mail::BIMI ' . ( $Mail::BIMI::Version // 'dev' ) . '/1.0';
    $http_client = HTTP::Tiny::Paranoid->new(
      agent => $agent,
      max_size => $self->http_client_max_fetch_size,
      max_redirect => $self->bimi_object->options->http_client_max_redirect,
      timeout => $self->bimi_object->options->http_client_timeout,
      verify_SSL => 1,     # Certificates MUST verify
      default_headers => {
        'accept-encoding' => 'identity',
      },
    );
    return $http_client;
  }
}

1;
