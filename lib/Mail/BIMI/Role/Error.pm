package Mail::BIMI::Role::Error;
# ABSTRACT: Class to model an error
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  has _error => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => sub{return []}, is_cacheable => 1 );

sub add_error($self,$error) {
  if ( ref $error eq 'ARRAY' ) {
    foreach my $suberror ( $error->@* ){
        $self->add_error($suberror);
    }
  }
  elsif ( ref $error eq 'HASH' ) {
      chomp $error->{error};
      chomp $error->{detail};
      push $self->_error->@*, $error;
  }
  else {
    chomp $error;
    push $self->_error->@*, { error => $error, detail => '' };
  }
}

sub error($self) {
  my @error = map { $_->{error} } $self->_error->@*;
  return \@error;
}

sub error_detail($self) {
  return $self->_error;
}

sub has_error($self,$error) {
  if ( grep { $_->{error} =~ /$error/ } $self->_error->@* ) {
    return 1;
  }
  return 0;
}

1;
