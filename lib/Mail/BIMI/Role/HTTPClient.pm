package Mail::BIMI::Role::HTTPClient;
# ABSTRACT: Class to model a DNS resolver
# VERSION
use 5.20.0;
use Moo::Role;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
use HTTP::Tiny::Paranoid;
  has http_client => ( is => 'rw', lazy => 1, builder => '_build_http_client' );
  has http_client_response => ( is => 'rw' );

{
  my $http_client;
  sub _build_http_client($self) {
    return $http_client if $http_client;
    my $agent = 'Mail::BIMI ' . ( $Mail::BIMI::Version // 'dev' );
    $http_client = HTTP::Tiny::Paranoid->new(
      agent => $agent,
      max_size => 65535,   # Allow for 50% compression over maximum payload size
      timeout => 5,        # Low timeout
      verify_SSL => 1,     # Certificates MUST verify
    );
    return $http_client;
  }
}

sub http_client_get($self,$url) {
  my $response = $self->http_client->get($url);
  $self->http_client_response($response);
  return $response->{content};
}

1;
