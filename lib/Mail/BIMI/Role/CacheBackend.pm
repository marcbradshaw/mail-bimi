package Mail::BIMI::Role::CacheBackend;
# ABSTRACT: Cache handling backend
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  has parent => ( is => 'ro', required => 1, weaken => 1,
    documentation => 'Parent class for cacheing' );
  with 'Mail::BIMI::Role::Base';
  requires 'get_from_cache';
  requires 'put_to_cache';
  requires 'delete_cache';

=head1 DESCRIPTION

Role for implementing a cache backend

=cut

1;
