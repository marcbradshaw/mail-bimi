package Mail::BIMI;
# ABSTRACT: BIMI object
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Record;
use Mail::BIMI::Result;
  with 'Mail::BIMI::Role::Resolver';
  with 'Mail::BIMI::Role::Constants';
  has domain => ( is => 'rw', isa => Str );
  has selector => ( is => 'rw', isa => Str, lazy => 1, builder => sub{ return 'default' } );
  has dmarc_object => ( is => 'rw', isa => class_type('Mail::DMARC::Result') );
  has spf_object => ( is => 'rw', isa => class_type('Mail::SPF::Result') );
  has record => ( is => 'rw', lazy => 1, builder => '_build_record' );
  has result => ( is => 'rw', lazy => 1, builder => '_build_result' );

sub _build_record($self) {
  croak 'Domain required' if ! $self->domain;
  return Mail::BIMI::Record->new( domain => $self->domain, selector => $self->selector, resolver => $self->resolver );
}

sub _build_result($self) {
  croak 'Domain required' if ! $self->domain;

  my $result = Mail::BIMI::Result->new(
    parent => $self,
  );

  # does DMARC pass
  if ( ! $self->dmarc_object ) {
    $result->set_result( 'skipped', $self->NO_DMARC );
    return $result;
  }
  if ( $self->dmarc_object->result ne 'pass' ) {
      $result->set_result( 'skipped', 'DMARC ' . $self->dmarc_object->result );
      return $result;
  }

  if ( $self->spf_object ) {
      my $spf_request = $self->spf_object->request;
      if ( $spf_request ) {
          my $spf_record = $spf_request->record;
          if ( $spf_record ) {
              my @spf_terms = $spf_record->terms;
              if ( @spf_terms ) {
                    my $last_term = pop @spf_terms;
                    if ( $last_term->name eq 'all' && $last_term->qualifier eq '+') {
                        $result->set_result( 'skipped', $self->SPF_PLUS_ALL );
                        return $result;
                    }
                }
            }
        }
    }

  if ( ! $self->record->is_valid ) {
    if ( $self->record->has_error( $self->NO_BIMI_RECORD ) ) {
      $result->set_result( 'none', $self->BIMI_NOT_ENABLED );
    }
    elsif ( $self->record->has_error( $self->DNS_ERROR ) ) {
      $result->set_result( 'none', $self->DNS_ERROR );
    }
    else {
      my @fail_errors = qw{
        NO_DMARC
        MULTI_BIMI_RECORD
        DUPLICATE_KEY
        EMPTY_L_TAG
        EMPTY_V_TAG
        INVALID_V_TAG
        MISSING_L_TAG
        MISSING_V_TAG
        MULTIPLE_AUTHORITIES
        MULTIPLE_LOCATIONS
        INVALID_TRANSPORT_A
        INVALID_TRANSPORT_L
        SPF_PLUS_ALL
        SVG_FETCH_ERROR
        SVG_GET_ERROR
        SVG_SIZE
        SVG_UNZIP_ERROR
        SVG_INVALID_XML
        SVG_VALIDATION_ERROR };
      my $found_error = 0;
      foreach my $fail_error (@fail_errors) {
        if ( $self->record->has_error( $self->$fail_error ) ) {
          $found_error = 1;
          $result->set_result( 'fail', $self->$fail_error );
          last;
        }
      }
      if ( !$found_error ) {
        $result->set_result( 'fail', $self->BIMI_INVALID );
      }
    }
    return $result;
  }

  $result->set_result( 'pass', '' );

  return $result;
}


1;
