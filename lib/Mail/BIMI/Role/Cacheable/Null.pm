package Mail::BIMI::Role::Cacheable::Null;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
use Digest::SHA256;

=head1 DESCRIPTION

Cache worker Role for Null storage

=cut

sub _get_from_cache($self) {
  return;
}

sub _put_to_cache($self,$data) {
  return;
}

sub _delete_cache($self) {
  return;
}

1;

