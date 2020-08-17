package Mail::BIMI::VMC::Chain;
# ABSTRACT: Class to model a VMC Chain
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::VMC::Cert;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify 0.20;
use Term::ANSIColor qw{ :constants };

with(
  'Mail::BIMI::Role::Base',
  'Mail::BIMI::Role::HasError',
);
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
  return 0 if !$self->vmc;
  my $root_ca = Crypt::OpenSSL::Verify->new($self->bimi_object->options->ssl_root_cert,{noCApath=>0});
  my $root_ca_ascii = scalar read_file $self->bimi_object->options->ssl_root_cert;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $i = $cert->index;
    if ($cert->is_expired) {
      warn "Certificate $i is expired" if $self->bimi_object->options->verbose;
      next;
    }
    if ( !$cert->is_valid ) {
      warn "Certificate $i is not valid" if $self->bimi_object->options->verbose;
      next;
    }
    my $is_valid = 0;
    eval {
      $root_ca->verify($cert->object);
      $is_valid = 1;
    };
    if ( !$is_valid ) {
      warn "Certificate $i not directly validated to root" if $self->bimi_object->options->verbose;
      # NOP
    }
    else {
      warn "Certificate $i directly validated to root" if $self->bimi_object->options->verbose;
      $cert->validated_by($root_ca_ascii);
      $cert->validated_by_id(0);
      $cert->valid_to_root(1);
    }
    my $exts = eval{ $cert->object->extensions_by_oid() };
  }

  my $work_done;
  do {
    $work_done = 0;
    VALIDATED_CERT:
    foreach my $validated_cert ( $self->cert_object_list->@* ) {
      next VALIDATED_CERT if ! $validated_cert->valid_to_root;
      my $validated_i = $validated_cert->index;
      VALIDATING_CERT:
      foreach my $validating_cert ( $self->cert_object_list->@* ) {
        next VALIDATING_CERT if $validating_cert->valid_to_root;
        my $validating_i = $validating_cert->index;
        if ($validating_cert->is_expired) {
          warn "Certificate $validating_i is expired" if $self->bimi_object->options->verbose;
          next;
        }
        if ( !$validating_cert->is_valid ) {
          warn "Certificate $validating_i is not valid" if $self->bimi_object->options->verbose;
          next VALIDATING_CERT;
        }
        eval{
          $validated_cert->verifier->verify($validating_cert->object);
          warn "Certificate $validating_i validated to root via certificate $validated_i" if $self->bimi_object->options->verbose;
          $validating_cert->validated_by($validated_cert->full_chain);
          $validating_cert->validated_by_id($validated_i);
          $validating_cert->valid_to_root(1);
          $work_done = 1;
        };
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
    my $exts = eval{ $object->extensions_by_oid() };
    next if !$exts;
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
  my $i = 1;
  foreach my $cert ( $self->cert_list->@* ) {
    push @objects, Mail::BIMI::VMC::Cert->new(
      bimi_object => $self->bimi_object,
      chain => $self,
      ascii => $cert,
      index => $i++,
    );
  }
  return \@objects;
}

=method I<app_validate()>

Output human readable validation status of this object

=cut

sub app_validate($self) {
  say 'Certificate Chain Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $i = $cert->index;
    my $obj = $cert->object;
    say '';
    say YELLOW.'  Certificate '.$i.WHITE.': '.($cert->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
    if ( $obj ) {
      say YELLOW.'  Subject          '.WHITE.': '.CYAN.($obj->subject//'-none-').RESET;
      say YELLOW.'  Not Before       '.WHITE.': '.CYAN.($obj->notBefore//'-none-').RESET;
      say YELLOW.'  Not After        '.WHITE.': '.CYAN.($obj->notAfter//'-none-').RESET;
      say YELLOW.'  Issuer           '.WHITE.': '.CYAN.($obj->issuer//'-none-').RESET;
      say YELLOW.'  Expired          '.WHITE.': '.($obj->checkend(0)?BRIGHT_RED.'Yes':GREEN.'No').RESET;
      my $exts = eval{ $obj->extensions_by_oid() };
      if ( $exts ) {
        my $alt_name = exists $exts->{'2.5.29.17'} ? $exts->{'2.5.29.17'}->to_string : '-none-';
        say YELLOW.'  Alt Name         '.WHITE.': '.CYAN.($alt_name//'-none-').RESET;
        say YELLOW.'  Has LogotypeExtn '.WHITE.': '.CYAN.(exists($exts->{'1.3.6.1.5.5.7.1.12'})?GREEN.'Yes':BRIGHT_RED.'No').RESET;
      }
      else {
        say YELLOW.'  Extensions       '.WHITE.': '.BRIGHT_RED.'NOT FOUND'.RESET;
      }
      say YELLOW.'  Has Valid Usage  '.WHITE.': '.CYAN.($cert->has_valid_usage?GREEN.'Yes':BRIGHT_RED.'No').RESET;
    }
    say YELLOW.'  Valid to Root    '.WHITE.': '.CYAN.($cert->valid_to_root?GREEN.($cert->validated_by_id == 0?'Direct':'Via cert '.$cert->validated_by_id):BRIGHT_RED.'No').RESET;
    say YELLOW.'  Is Valid         '.WHITE.': '.CYAN.($cert->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  }
}

1;

