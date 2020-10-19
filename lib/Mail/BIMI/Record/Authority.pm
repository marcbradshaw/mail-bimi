package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::VMC;

extends 'Mail::BIMI::Base';
with 'Mail::BIMI::Role::HasError';
has is_authority_valid => ( is => 'rw', lazy => 1, builder => '_build_is_authority_valid' );
has uri => ( is => 'rw', isa => 'Maybe[Str]', required => 1,
  documentation => 'inputs: URI of VMC', );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Is this Authority valid' );
has vmc => ( is => 'rw', lazy => 1, builder => '_build_vmc',
  documentation => 'Mail::BIMI::VMC object for this Authority' );

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI authority attribute

=cut

sub _build_is_authority_valid($self) {
  return 1 if !defined $self->uri;
  return 1 if $self->uri eq '';
  return 1 if $self->uri eq 'self';
  if ( ! ( $self->uri =~ /^https:\/\// ) ) {
    $self->add_error('INVALID_TRANSPORT_A');
  }

  # Currently .pem implies VMC, and is the only evidence document defined
  # Expand this as more options become available
  if ( !( $self->uri =~ /\.pem\?/ || $self->uri =~ /\.pem$/ )) {
    $self->add_error('INVALID_EXTENSION_A','VMC MUST have .pem extension');
  }

  return 0 if $self->errors->@*;
  return 1;
}

=method I<is_relevant()>

Return true if this Authority is relevant to validation

=cut

sub is_relevant($self) {
  return 0 if !defined $self->uri;
  return 0 if $self->uri eq '';
  return 0 if $self->uri eq 'self';
  return 0 if $self->bimi_object->options->no_validate_cert;
  $self->log_verbose('Authority is relevant');
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->is_authority_valid;
  if ( $self->is_relevant && !$self->vmc->is_valid ) {
    $self->add_error_object( $self->vmc->errors );
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('Authority is valid');
  return 1;
}

sub _build_vmc($self) {
  return if !$self->is_authority_valid;
  return if !$self->is_relevant;
  my $check_domain = $self->bimi_object->domain;
  return Mail::BIMI::VMC->new( check_domain => $check_domain, uri => $self->uri, bimi_object => $self->bimi_object );
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->vmc->finish if $self->vmc;
}

1;
