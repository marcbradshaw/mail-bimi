package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::VMC;
  with(
    'Mail::BIMI::Role::Base',
    'Mail::BIMI::Role::Error',
  );
  has _is_valid => ( is => 'rw', lazy => 1, builder => '_build__is_valid' );
  has authority => ( is => 'rw', isa => sub{!defined $_[0] || Str}, required => 1,
    documentation => 'URI of VMC', pod_section => 'inputs' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
    documentation => 'Is this Authority valid' );
  has vmc => ( is => 'rw', lazy => 1, builder => '_build_vmc',
    documentation => 'Mail::BIMI::VMC object for this Authority' );

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI authority attribute

=cut

sub _build__is_valid($self) {
  return 1 if !defined $self->authority;
  return 1 if $self->authority eq '';
  return 1 if $self->authority eq 'self';
  if ( ! ( $self->authority =~ /^https:\/\// ) ) {
    $self->add_error( $self->ERR_INVALID_TRANSPORT_A );
  }

  return 0 if $self->error->@*;
  return 1;
}

=method I<is_relevant()>

Return trus if this Authority is relevant to validation

=cut

sub is_relevant($self) {
  return 0 if !defined $self->authority;
  return 0 if $self->authority eq '';
  return 0 if $self->authority eq 'self';
  return 0 if $self->bimi_object->OPT_NO_VALIDATE_CERT;
  warn 'Authority is relevant' if $self->bimi_object->OPT_VERBOSE;
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->_is_valid;
  if ( $self->is_relevant && !$self->vmc->is_valid ) {
    $self->add_error( $self->vmc->error );
  }

  return 0 if $self->error->@*;
  warn 'Authority is valid' if $self->bimi_object->OPT_VERBOSE;
  return 1;
}

sub _build_vmc($self) {
  return if !$self->_is_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::VMC->new( authority => $self->authority, bimi_object => $self->bimi_object );
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->vmc->finish if $self->vmc;
}

1;
