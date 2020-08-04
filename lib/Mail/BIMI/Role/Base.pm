package Mail::BIMI::Role::Base;
# ABSTRACT: Base role for Mail::BIMI subclasses
# VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
  has bimi_object => ( is => 'ro', isa => 'Mail::BIMI', required => 1, weak_ref => 1,
    documentation => 'Base Mail::BIMI object for this operation' );

=head1 DESCRIPTION

Base BIMI Role with common methods and attributes

=cut

=method I<record_object()>

Return the current Mail::BIMI::Record object for this operation

=cut

sub record_object($self) {
  return $self->bimi_object->record;
}

=method I<authority_object()>

Return the current Mail::BIMI::Authority object for this operation

=cut

sub authority_object($self) {
  return unless $self->record_object;
  return $self->record_object->authority;
}

1;

