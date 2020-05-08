package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
# VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
  with 'Mail::BIMI::Role::Error';
  has authority => ( is => 'rw', isa => ArrayRef, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );

sub _build_is_valid($self) {

  foreach my $authority ( $self->authority->@* ) {
    if ( $authority eq '' ) {
      $self->add_error( $self->EMPTY_L_TAG );
    }
    elsif ( ! ( $authority =~ /^https:\/\// ) ) {
      $self->add_error( $self->INVALID_TRANSPORT_A );
    }
  }

  if ( scalar $self->authority->@* > 1 ) {
    $self->add_error( $self->MULTIPLE_AUTHORITIES );
  }

  return 0 if $self->error->@*;
  return 1;
}

1;
