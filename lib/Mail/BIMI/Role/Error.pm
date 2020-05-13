package Mail::BIMI::Role::Error;
# ABSTRACT: Class to model an error
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  has error => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => sub{return []}, is_cacheable => 1 );

sub add_error($self,$error) {
  if ( ref $error eq 'ARRAY' ) {
    chomp $error->@*;
    push $self->error->@*, $error->@*;
  }
  else {
    chomp $error;
    push $self->error->@*, $error;
  }
}

sub has_error($self,$error) {
  if ( grep { $_ =~ /$error/ } $self->error->@* ) {
    return 1;
  }
  return 0;
}

1;
