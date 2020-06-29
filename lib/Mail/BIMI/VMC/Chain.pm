package Mail::BIMI::VMC::Chain;
# ABSTRACT: Class to model a VMC Chain
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::VMC::Cert;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify;
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Error';
  has cert_list => ( is => 'rw', isa => ArrayRef,
    documentation => 'ArrayRef of individual Certificates in the chain' );
  has cert_object_list => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => '_build_cert_object_list',
    documentation => 'ArrayRef of Crypt::OpenSSL::X509 objects for the Certificates in the chain' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
    documentation => 'Does the VMC of this chain validate back to root?' );
  has root_cert => ( is => 'rw', isa => Str,
    documentation => 'Root certificate file' );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Certificate Chain

=cut

sub _build_is_valid($self) {
  # Start with root cert validations
  my $root_ca = Crypt::OpenSSL::Verify->new(CAfile => $self->bimi_object->OPT_SSL_ROOT_CERT);
  foreach my $cert ( $self->cert_object_list->@* ) {
    eval{$root_ca->verify($cert->object)};
    if ( my $error = $@ ) {
      # NOP
    }
    else {
      $cert->valid_to_root(1);
    }
    if ( !$cert->is_valid ) {
      $self->add_error( $cert->error );
    }

  }

  my $work_done;
  do {
    $work_done = 0;
    VALIDATED_CERT:
    foreach my $validated_cert ( $self->cert_object_list->@* ) {
      next VALIDATED_CERT if ! $validated_cert->valid_to_root;
      VALIDATING_CERT:
      foreach my $validating_cert ( $self->cert_object_list->@* ) {
        next VALIDATING_CERT if $validating_cert->valid_to_root;
        eval{$validated_cert->verifier->verify($validating_cert->object)};
        if ( my $error = $@ ) {
          # NOP
        }
        else {
          $validating_cert->valid_to_root(1);
          $work_done = 1;
        }
      }
    }
  } until !$work_done;

  if ( !$self->vmc->valid_to_root ) {
     $self->add_error($self->ERR_VMC_PARSE_ERROR('Could not verify VMC'));
  }

  return 0 if $self->error->@*;
  return 1;
}

sub vmc($self) {
  my $vmc;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $object = $cert->object;
    next if !$object;
    my $exts = $object->extensions_by_oid();
    if ( $cert->has_valid_usage && exists $exts->{'1.3.6.1.5.5.7.1.12'}) {
      # Has both extended usage and embedded Indicator
      $self->add_error($self->ERR_VMC_VALIDATION_ERROR('Multiple VMCs found in chain')) if $vmc;
      $vmc = $cert;
    }
  }
  if ( !$vmc ) {
    $self->add_error($self->ERR_VMC_VALIDATION_ERROR('No valid VMC found in chain'));
  }
  return $vmc;
}

sub _build_cert_object_list($self) {
  my @objects;
  foreach my $cert ( $self->cert_list->@* ) {
    push @objects, Mail::BIMI::VMC::Cert->new(
      bimi_object => $self->bimi_object,
      chain => $self,
      ascii => $cert,
    );
  }
  return \@objects;
}

sub _build_is_cert_valid($self) {
  return 1 if $self->bimi_object->OPT_NO_VALIDATE_CERT;
  my $temp_fh = File::Temp->new(UNLINK=>0);
  my $temp_name = $temp_fh->filename;
  close $temp_fh;
  my $chain;
  my $cert_is_valid = 1;
  for (my  $i=scalar $self->cert_object_list->@* - 1;$i>=0;$i--) {
    my $ca = $chain
           ? Crypt::OpenSSL::Verify->new(CAfile => $temp_name)
           : Crypt::OpenSSL::Verify->new(CAfile => $self->bimi_object->OPT_SSL_ROOT_CERT);
    eval{$ca->verify($self->cert_object_list->[$i])};
    if ( my $error = $@ ) {
      $self->add_error($self->ERR_VMC_VALIDATION_ERROR($error));
      $cert_is_valid = 0;
      last;
    }

    $chain = join("\n",$self->cert_list->[$i]->@*);
    open $temp_fh, '>', $temp_name;
    print $temp_fh $chain;
    close $temp_fh;
  }
  unlink $temp_name;
  warn 'Cert is '.($cert_is_valid?'valid':'invalid') if $self->bimi_object->OPT_VERBOSE;

  return $cert_is_valid;
}

1;

