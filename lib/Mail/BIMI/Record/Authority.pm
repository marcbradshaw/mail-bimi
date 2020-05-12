package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
  with 'Mail::BIMI::Role::Error';
  has authority => ( is => 'rw', isa => sub{ undef || Str}, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );

sub _build_is_valid($self) {
  if ( ! ( $self->authority =~ /^https:\/\// ) ) {
    $self->add_error( $self->INVALID_TRANSPORT_A );
  }

  return 0 if $self->error->@*;
  return 1;
}

1;
