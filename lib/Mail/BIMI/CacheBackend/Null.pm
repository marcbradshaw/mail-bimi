package Mail::BIMI::CacheBackend::Null;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Digest::SHA256;

with 'Mail::BIMI::Role::CacheBackend';

=head1 DESCRIPTION

Cache worker Role for Null storage

=cut

sub get_from_cache($self) {
  return;
}

sub put_to_cache($self,$data) {
  return;
}

sub delete_cache($self) {
  return;
}

1;

