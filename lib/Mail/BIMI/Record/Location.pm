package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a collection of egress pools
# VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
  with 'Mail::BIMI::Role::Error';
  has location => ( is => 'rw', isa => ArrayRef, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );

sub _build_is_valid($self) {

  $self->add_error( 'No locations' ) if ! $self->location->@*;
  foreach my $location ( $self->location->@* ) {
    if ( ! ( $location =~ /^https:\/\// ) ) {
      $self->error( 'Invalid transport in l tag' );
    }
  }

  return 0 if $self->error->@*;
  return 1;
}


1;
