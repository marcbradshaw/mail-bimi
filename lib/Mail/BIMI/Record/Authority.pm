package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::VMC;
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Constants';
  with 'Mail::BIMI::Role::Error';
  has authority => ( is => 'rw', isa => sub{ undef || Str}, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );
  has _is_valid => ( is => 'rw', lazy => 1, builder => '_build__is_valid' );
  has vmc => ( is => 'rw', lazy => 1, builder => '_build_vmc' );

sub _build__is_valid($self) {
  return 1 if !defined $self->authority;
  return 1 if $self->authority eq '';
  return 1 if $self->authority eq 'self';
  if ( ! ( $self->authority =~ /^https:\/\// ) ) {
    $self->add_error( $self->INVALID_TRANSPORT_A );
  }

  return 0 if $self->error->@*;
  return 1;
}

sub is_relevant($self) {
  return 0 if !defined $self->authority;
  return 0 if $self->authority eq '';
  return 0 if $self->authority eq 'self';
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->_is_valid;
  if ( $self->is_relevant && !$self->vmc->is_valid ) {
    $self->add_error( $self->vmc->error );
  }

  return 0 if $self->error->@*;
  return 1;
}

sub _build_vmc($self) {
  return if !$self->_is_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::VMC->new( authority => $self->authority, bimi_object => $self->bimi_object );
}

1;
