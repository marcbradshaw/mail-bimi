package Mail::BIMI::Role::CacheBackend;
# ABSTRACT: Cache handling backend
# VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use Digest::SHA256;
  has parent => ( is => 'ro', required => 1, weak_ref => 1,
    documentation => 'Parent class for cacheing' );
  has _cache_hash => ( is => 'ro', lazy => 1, builder => '_build_cache_hash' );
  with 'Mail::BIMI::Role::Base';
  requires 'get_from_cache';
  requires 'put_to_cache';
  requires 'delete_cache';

=head1 DESCRIPTION

Role for implementing a cache backend

=cut

sub _build_cache_hash($self) {
  my $context = Digest::SHA256::new(512);
  ## TODO make sure there are no wide characters present in cache key
  my $hash = $context->hexhash( $self->parent->_cache_key );
  $hash =~ s/ //g;
  return $hash;
}

1;
