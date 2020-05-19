package Mail::BIMI::Role::Base;
# ABSTRACT: Base role for Mail::BIMI subclasses
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  has bimi_object => ( is => 'ro', isa => class_type('Mail::BIMI'), required => 1, weaken => 1);

sub record_object($self) {
  return $self->bimi_object->record;
}

sub authority_object($self) {
  return unless $self->record_object;
  return $self->record_object->authority;
}

1;

