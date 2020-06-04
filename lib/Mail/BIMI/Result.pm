package Mail::BIMI::Result;
# ABSTRACT: Class to model a BIMI result
# VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Comment;
  with 'Mail::BIMI::Role::Base';
  has result => ( is => 'rw', isa => Str,
    documentation => 'Text result' );
  has comment => ( is => 'rw', isa => Str,
    documentation => 'Text comment' );
  has headers => ( is => 'rw', isa => HashRef,
    documentation => 'Hashref of headers to add to message' );

=method I<domain()>

Return the domain of the current operation

=cut

sub domain($self) {
  return $self->bimi_object->domain;
}

=method I<selector()>

Return the selector of the current operation

=cut

sub selector($self) {
  return $self->bimi_object->selector;
}

=method I<set_result($result,$comment)>

Set the result text and comment for this Result object

=cut

sub set_result($self,$result,$comment) {
  $self->result($result);
  $self->comment($comment);
}

=method I<get_authentication_results_object()>

Returns a Mail::AuthenticationResults::Header::Entry object with the BIMI results set

=cut

sub get_authentication_results_object($self) {
  my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'bimi' )->safe_set_value( $self->result );
  if ( $self->comment ) {
    $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( $self->comment ) );
  }
  if ( $self->result eq 'pass' ) {
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.d' )->safe_set_value( $self->bimi_object->record->domain ) );
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.selector' )->safe_set_value( $self->bimi_object->record->selector ) );
  }
  if ( $self->bimi_object->record->authority->is_relevant ) {
    my $vmc = $self->bimi_object->record->authority->vmc;
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'policy.authority' )->safe_set_value( $vmc->is_valid ? 'pass' : 'fail' ) );
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'policy.authority-uri' )->safe_set_value( $self->bimi_object->record->authority->authority ) );
  }

  return $header;
}

=method I<get_authentication_results()>

Return the BIMI Authentication-Results fragment as text

=cut

sub get_authentication_results($self) {
  return $self->get_authentication_results_object->as_string;
}

1;
