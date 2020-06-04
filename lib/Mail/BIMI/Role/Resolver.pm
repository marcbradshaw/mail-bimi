package Mail::BIMI::Role::Resolver;
# ABSTRACT: Class to model a DNS resolver
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
use Net::DNS::Resolver;
  has resolver => ( is => 'rw', lazy => 1, builder => '_build_resolver',
    documentation => 'Net::DNS::Resolver object to use for DNS lookups' );

sub _build_resolver($self) {
  my $timeout = 5;
  my $resolver = Net::DNS::Resolver->new(dnsrch => 0);
  $resolver->tcp_timeout( $timeout );
  $resolver->udp_timeout( $timeout );
  return $resolver;
}

1;
