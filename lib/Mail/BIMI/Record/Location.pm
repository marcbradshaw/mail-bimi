package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a BIMI location
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Identifier;
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::Constants';
  has location => ( is => 'rw', isa => ArrayRef, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );
  has identifier => ( is => 'rw', lazy => 1, builder => '_build_identifier' );

sub _build_is_valid($self) {

  foreach my $location ( $self->location->@* ) {
    if ( $location eq '' ) {
      $self->add_error( $self->EMPTY_L_TAG );
    }
    elsif ( ! ( $location =~ /^https:\/\// ) ) {
      $self->add_error( $self->INVALID_TRANSPORT_L );
    }
  }

  if ( scalar $self->location->@* > 1 ) {
    $self->add_error( $self->MULTIPLE_LOCATIONS );
  }

  return 0 if $self->error->@*;
  return 1;
}

sub _build_identifier($self) {
  return if ! $self->is_valid;
  return Mail::BIMI::Identifier->new( location => $self->location->[0] );
}

1;
