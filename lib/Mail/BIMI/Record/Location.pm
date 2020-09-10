package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a BIMI location
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::Indicator;

extends 'Mail::BIMI::Base';
with 'Mail::BIMI::Role::HasError';
has is_location_valid => ( is => 'rw', lazy => 1, builder => '_build_is_location_valid' );
has uri => ( is => 'rw', isa => 'Maybe[Str]', required => 1,
  documentation => 'inputs: URI of Indicator', );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Is this Location record valid' );
has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
  documentation => 'Mail::BIMI::Indicator object for this location' );
has is_relevant => ( is => 'rw', lazy => 1, default => sub{return 1},
  documentation => 'Is the location relevant' );

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI location attribute

=cut

sub _build_is_location_valid($self) {
  # Check is_valid without checking indicator, because recursion!
  if ( !defined $self->uri ) {
    $self->add_error('MISSING_L_TAG');
  }
  elsif ( $self->uri eq '' ) {
    $self->add_error('EMPTY_L_TAG');
  }
  elsif ( ! ( $self->uri =~ /^https:\/\// ) ) {
    $self->add_error('INVALID_TRANSPORT_L');
  }
  else {
  }

  return 0 if $self->errors->@*;
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->is_location_valid;
  if ( !$self->indicator->is_valid ) {
    $self->add_error_object( $self->indicator->errors );
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('Location is valid');
  return 1;
}

sub _build_indicator($self) {
  return if !$self->is_location_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::Indicator->new( uri => $self->uri, bimi_object => $self->bimi_object, source => 'Location' );
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->indicator->finish if $self->indicator;
}

1;
