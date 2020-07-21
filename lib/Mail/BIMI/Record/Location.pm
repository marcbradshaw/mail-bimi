package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a BIMI location
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Indicator;
  with(
    'Mail::BIMI::Role::Base',
    'Mail::BIMI::Role::Error',
  );
  has _is_valid => ( is => 'rw', lazy => 1, builder => '_build__is_valid' );
  has location => ( is => 'rw', isa => sub{!defined$_[0] || Str }, required => 1,
    documentation => 'URI of Indicator', pod_section => 'inputs' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
    documentation => 'Is this Location record valid' );
  has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
    documentation => 'Mail::BIMI::Indicator object for this location' );
  has is_relevant => ( is => 'rw', lazy => 1, builder => sub{return 1;},
    documentation => 'Is the location relevant' );

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI location attribute

=cut

sub _build__is_valid($self) {
  # Check is_valid without checking indicator, because recursion!
  if ( !defined $self->location ) {
    $self->add_error( $self->ERR_MISSING_L_TAG );
  }
  elsif ( $self->location eq '' ) {
    $self->add_error( $self->ERR_EMPTY_L_TAG );
  }
  elsif ( ! ( $self->location =~ /^https:\/\// ) ) {
    $self->add_error( $self->ERR_INVALID_TRANSPORT_L );
  }
  else {
  }

  return 0 if $self->error->@*;
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->_is_valid;
  if ( !$self->indicator->is_valid ) {
    $self->add_error( $self->indicator->error );
  }

  return 0 if $self->error->@*;
  warn 'Location is valid' if $self->bimi_object->OPT_VERBOSE;
  return 1;
}

sub _build_indicator($self) {
  return if !$self->_is_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::Indicator->new( location => $self->location, bimi_object => $self->bimi_object );
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->indicator->finish if $self->indicator;
}

1;
