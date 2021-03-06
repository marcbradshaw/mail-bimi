package Mail::BIMI::Base;
# ABSTRACT: Base class for Mail::BIMI subclasses
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

has bimi_object => ( is => 'ro', isa => 'Mail::BIMI', required => 1, weak_ref => 1,
  documentation => 'Base Mail::BIMI object for this operation' );

=head1 DESCRIPTION

Base BIMI class with common methods and attributes

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

=method I<log_verbose()>

Output given text if in verbose mode.

=cut

sub log_verbose($self,$text) {
  $self->bimi_object->log_verbose($text);
}

1;

