package Mail::BIMI::CacheBackend::FastMmap;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Cache::FastMmap;
  with 'Mail::BIMI::Role::CacheBackend';
  has _cache_fastmmap => ( is => 'rw', lazy => 1, builder => '_build_cache_fastmmap' );

=head1 DESCRIPTION

Cache worker role for Cache::FastMmap backend

=cut

sub _build_cache_fastmmap($self) {
  my $cache_filename = $self->bimi_object->OPT_CACHE_FASTMMAP_SHARE_FILE;
  my $init_file = -e $cache_filename ? 0 : 1;
  my $cache = Cache::FastMmap->new( share_file => $cache_filename, serializer => 'json', init_file => $init_file, unlink_on_exit => 0 );
  return $cache;
}

sub get_from_cache($self) {
  return $self->_cache_fastmmap->get($self->_cache_hash);
}

sub put_to_cache($self,$data) {
  $self->_cache_fastmmap->set($self->_cache_hash,$data);
}

sub delete_cache($self) {
  $self->_cache_fastmmap->remove($self->_cache_hash);
}

1;

