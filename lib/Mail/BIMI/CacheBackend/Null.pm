package Mail::BIMI::CacheBackend::Null;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

with 'Mail::BIMI::Role::CacheBackend';

=head1 DESCRIPTION

Cache worker Role for Null storage

=cut

=method I<get_from_cache()>

Retrieve this class data from cache

=cut

sub get_from_cache($self) {
  return;
}

=method I<put_to_cache($data)>

Put this classes data into the cache

=cut

sub put_to_cache($self,$data) {
  return;
}

=method I<delete_cache>

Delete the cache entry for this class

=cut

sub delete_cache($self) {
  return;
}

1;

