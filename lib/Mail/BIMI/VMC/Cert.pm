package Mail::BIMI::VMC::Cert;
# ABSTRACT: Class to model a VMC Cert
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Convert::ASN1;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify 0.20;
use File::Temp qw{ tempfile };
  with(
    'Mail::BIMI::Role::Base',
    'Mail::BIMI::Role::Data',
    'Mail::BIMI::Role::Error',
  );
  has chain => ( is => 'rw', isa => class_type('Mail::BIMI::VMC::Chain'), required => 1, weak_ref => 1,
    documentation => 'Back reference to the chain' );
  has ascii => ( is => 'rw', isa => ArrayRef, required => 1,
    documentation => 'Raw data of the Cert contents', pod_section => 'inputs' );
  has object => ( is => 'rw', isa => sub{!defined $_[0] || class_type('Crypt::OpenSSL::X509')}, lazy => 1, builder => '_build_object',
    documentation => 'Crypt::OpenSSL::X509 object for the Certificate' );
  has verifier => ( is => 'rw', isa => class_type('Crypt::OpenSSL::Verify'), lazy => 1, builder => '_build_verifier',
    documentation => 'Crypt::OpenSSL::Verify object for the Certificate' );
  has valid_to_root => ( is => 'rw',
    documentation => 'Could we validate this certificate to the root certs, set by Mail::BIMI::VMC::Chain->is_valid' );
  has filename => ( is => 'rw', lazy => 1, builder => '_build_filename',
    documentation => 'Filename of temporary file containing the cert' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
    documentation => 'Is this a valid Cert?' );
  has indicator_asn => ( is => 'rw', lazy => 1, builder => '_build_indicator_asn',
    documentation => 'Parsed ASN data for the embedded Indicator' );
  has index => ( is => 'rw', required => 1,
    documentation => 'Index of this certificate in the chain' );
  has validated_by => ( is => 'rw',
    documentation => 'Root and/or intermediate certificate in the chain used to verify this certificate' );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Certificate

=cut

sub DESTROY {
  my ($self) = @_;
  unlink $self->{filename} if $self->{filename} && -f $self->{filename};
}

sub _build_is_valid($self) {
  $self->object; # trigger object parse
  return 0 if $self->error->@*;
  return 1;
}

sub _build_indicator_asn($self) {
  return if !$self->object;
  my $exts = eval{ $self->object->extensions_by_oid() };
  return if !$exts;
  return if !exists $exts->{'1.3.6.1.5.5.7.1.12'};
  my $indhex = $exts->{'1.3.6.1.5.5.7.1.12'}->value;
  $indhex =~ s/^#//;
  my $indicator = pack("H*",$indhex);
  my $asn = Convert::ASN1->new;
  $asn->prepare_file($self->get_file_name('asn1.txt'));
  my $decoder = $asn->find('LogotypeExtn');
  die $asn->error if $asn->error;
  my $decoded = $decoder->decode($indicator);
  if ( $decoder->error ) {
    $self->add_error($self->ERR_VMC_PARSE_ERROR($decoder->error));
    return;
  }

  #my $image_details = $decoded->{subjectLogo}->{direct}->{image}->[0]->{imageDetails};
  #my $mime_type = $image_details->{mediaType};
  #my $logo_hash = $image_details->{logotypeHash}->[0];
  return $decoded;
}

sub _build_object($self) {
  my $cert;
  eval{
    $cert = Crypt::OpenSSL::X509->new_from_string(join("\n",$self->ascii->@*));
    1;
  } || do {
    my $error = $@;
    chomp $error;
    $error =~ s/\. at .*$//;
    $self->add_error($self->ERR_VMC_PARSE_ERROR($error));
    return;
  };
  return $cert;
}

sub _build_verifier($self) {
  return Crypt::OpenSSL::Verify->new($self->filename,{noCApath=>1});
}

=method I<is_expired()>

Return true if this cert has expired

=cut

sub is_expired($self) {
  return 0 if !$self->object;
  my $seconds = 0;
  if ($self->object->checkend($seconds)) {
    return 1;
  }
  return 0;
}

=method I<has_valid_usage()>

Return true if this VMC has a valid usage extension for BIMI

=cut

sub has_valid_usage($self) {
  return if !$self->object;
  my $exts = eval{ $self->object->extensions_by_oid() };
  return if !$exts;
  my $extended_usage = $exts->{'2.5.29.37'};
  return if !$extended_usage;
  my $extended_usage_string = $extended_usage->to_string;
  return 1 if $extended_usage_string eq '1.3.6.1.5.5.7.3.31';
  return 0;
}

=method I<full_chain()>

The full chain of this certificate as verified to root

=cut

sub full_chain($self) {
  return join("\n",$self->ascii->@*,$self->validated_by);
}

sub _build_filename($self) {
  my $temp_fh = File::Temp->new(UNLINK=>0);
  my $temp_name = $temp_fh->filename;
  close $temp_fh;
  write_file($temp_name,$self->full_chain);
  return $temp_name;
}

1;
