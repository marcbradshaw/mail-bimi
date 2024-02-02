package Mail::BIMI::Role::HasHTTPClient;
# ABSTRACT: Class to model a HTTP client
# VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use HTTP::Tiny::Paranoid;
use Time::HiRes qw{ualarm};

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

=method I<http_client_get($uri)>

Perform a get request for the given $uri, wrapped with a timeout
to catch timeouts that the HTTP::Tiny timeout does not catch.

=cut

sub http_client_get($self, $uri) {
  # Set an overall hard timeout 1/10 second longer than the timeout we
  # pass to the client object.
  my $timeout = ($self->bimi_object->options->http_client_timeout * 1000000) + 100000;

  my $result;
  my $old_alarm;
  my $timed_out = 0;

  # Maintain an internal list of servers giving us a timeout, and do not
  # retry those for the duration of our current overall scope.
  $self->bimi_object->{_http_client_failed_server_list} = {}
    unless exists $self->bimi_object->{_http_client_failed_server_list};

  my ($server) = $uri =~ m/^[^:]*:\/\/([^\/]*)\/.*/;
  $server = lc ($server // '');

  if (exists $self->bimi_object->{_http_client_failed_server_list}->{$server}) {
    return {
      success => 0,
      status => 599,
    };
  }

  eval{
    $old_alarm = ualarm($timeout);
    local $SIG{ALRM} = sub { $timed_out = 1; die; };
    $result = $self->http_client->get($uri);
  };
  my $error = $@;
  ualarm($old_alarm);

  if ($timed_out) {
    $self->bimi_object->{_http_client_failed_server_list}->{$server} = 1;
    return {
      success => 0,
      status => 599,
    };
  }

  die $error if $error; # rethrow if the error wasn't our timeout

  $self->bimi_object->{_http_client_failed_server_list}->{$server} = 1 if $result->{status} == 599;

  return $result;
}

1;
