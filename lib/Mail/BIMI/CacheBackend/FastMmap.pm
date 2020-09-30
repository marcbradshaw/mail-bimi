package Mail::BIMI::CacheBackend::FastMmap;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Cache::FastMmap;

with 'Mail::BIMI::Role::CacheBackend';
has _cache_fastmmap => ( is => 'rw', lazy => 1, builder => '_build_cache_fastmmap' );

=head1 DESCRIPTION

Cache worker role for Cache::FastMmap backend

=cut

sub _build_cache_fastmmap($self) {
  my $cache_filename = $self->parent->bimi_object->options->cache_fastmmap_share_file;
  my $init_file = -e $cache_filename ? 0 : 1;
  my $cache = Cache::FastMmap->new( share_file => $cache_filename, serializer => 'sereal', init_file => $init_file, unlink_on_exit => 0 );
  return $cache;
}

=method I<get_from_cache()>

Retrieve this class data from cache

=cut

sub get_from_cache($self) {
  return $self->_cache_fastmmap->get($self->_cache_hash);
}

=method I<put_to_cache($data)>

Put this classes data into the cache

=cut

sub put_to_cache($self,$data) {
  $self->_cache_fastmmap->set($self->_cache_hash,$data);
}

=method I<delete_cache>

Delete the cache entry for this class

=cut

sub delete_cache($self) {
  $self->_cache_fastmmap->remove($self->_cache_hash);
}

1;

