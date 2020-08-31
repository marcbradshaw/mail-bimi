package Mail::BIMI::Role::HasError;
# ABSTRACT: Class to model an error
# VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use Mail::BIMI::Trait::Cacheable;
use Mail::BIMI::Trait::CacheSerial;
use Mail::BIMI::Error;
use Sub::Install;

has error => ( is => 'rw', isa => 'ArrayRef', lazy => 1, default => sub{return []}, traits => ['Cacheable','CacheSerial'] );

=head1 DESCRIPTION

Role for handling validation errors

=cut

=method I<serialize_error()>

Serialize the error property for cache storage

=cut

sub serialize_error($self) {
  my @data = map {{
    code => $_->code,
    detail => $_->detail,
  }} $self->error->@*;
  return \@data;
}

=method I<deserialize_error($value)>

De-serialize the error property for cache storage

=cut

sub deserialize_error($self,$value) {
  foreach my $error ($value->@*) {
    my $error_object = Mail::BIMI::Error->new(
      code => $error->{code},
      ( $error->{detail} ? ( detail => $error->{detail} ) : () ),
    );
    $self->add_error_object($error_object);
  }
}

=method I<add_error($code,$detail)>

Add an error with the given code and optional detail to the current operation.

=cut

sub add_error($self,$code,$detail=undef) {
  my $error = Mail::BIMI::Error->new(
    code=>$code,
    ($detail?(detail=>$detail):()),
  );
  $self->add_error_object($error);
}

=method I<add_error_object($error)>

Add an existing error object, or objects, to the current operation

=cut

sub add_error_object($self,$error) {
  if ( ref $error eq 'ARRAY' ) {
    foreach my $suberror ( $error->@* ){
        $self->add_error_object($suberror);
    }
  }
  else {
    $self->verbose(join(' : ',
      'Error',
      $error->code,
      $error->description,
      ( $error->detail ? $error->detail : () ),
    ));
    push $self->error->@*, $error;
  }
}

=method I<error_codes>

Return an ArrayRef of current error codes

=cut

sub error_codes($self) {
  my @error_codes = map { $_->code } $self->error->@*;
  return \@error_codes;
}

=method I<filter_errors($error)>

Return error(s) matching the given error code

=cut

sub filter_errors($self,$error) {
  return grep { $_->code eq $error } $self->error->@*;
}

1;
