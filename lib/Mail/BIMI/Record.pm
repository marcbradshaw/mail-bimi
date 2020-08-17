package Mail::BIMI::Record;
# ABSTRACT: Class to model a BIMI record
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Term::ANSIColor qw{ :constants };
use Mail::BIMI::Record::Authority;
use Mail::BIMI::Record::Location;
use Mail::DMARC::PurePerl;

with(
  'Mail::BIMI::Role::Base',
  'Mail::BIMI::Role::Error',
  'Mail::BIMI::Role::Cacheable',
);
has domain => ( is => 'rw', isa => Str, required => 1, traits => ['CacheKey'],
  documentation => 'inputs: Domain the for the record; will become fallback domain if used', );
has retrieved_record => ( is => 'rw', traits => ['Cacheable'],
  documentation => 'Record as retrieved' );
has selector => ( is => 'rw', isa => Str, traits => ['CacheKey'],
  documentation => 'inputs: Selector used to retrieve the record; will become default if fallback was used', );
has version => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_version', traits => ['Cacheable'],
  documentation => 'BIMI Version tag' );
has authority => ( is => 'rw', isa => 'Mail::BIMI::Record::Authority', lazy => 1, builder => '_build_authority',
  documentation => 'Mail::BIMI::Record::Authority object for this record' );
has location => ( is => 'rw', isa => 'Mail::BIMI::Record::Location', lazy => 1, builder => '_build_location',
  documentation => 'Mail::BIMI::Record::Location object for this record' );
has record => ( is => 'rw', isa => HashRef, lazy => 1, builder => '_build_record', traits => ['Cacheable'],
  documentation => 'Hashref of record values' );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', traits => ['Cacheable'],
  documentation => 'Is this record valid' );

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a BIMI Record

=cut

sub cache_valid_for($self) { return 3600 }

sub _build_version($self) {
  my $version;
  if ( exists $self->record->{v} ) {
    $version = $self->record->{v} // '';
  }
  return $version;
}

sub _build_authority($self) {
  my $uri;
  if ( exists $self->record->{a} ) {
    $uri = $self->record->{a} // '';
  }
  # TODO better parser here
  return Mail::BIMI::Record::Authority->new( uri => $uri, bimi_object => $self->bimi_object );
}

sub _build_location($self) {
  my $uri;
  if ( exists $self->record->{l} ) {
    $uri = $self->record->{l} // '';
  }
  # TODO better parser here
  # Need to decode , and ; as per spec>
  my $location = Mail::BIMI::Record::Location->new( uri => $uri, is_relevant => $self->location_is_relevant, bimi_object => $self->bimi_object );
  return $location;
}

=method I<location_is_relevant()>

Return true is the location is relevant to the validation of the record.

If we don't have a relevant authority, or we are checking BOTH authority and location.

=cut

sub location_is_relevant($self) {
  # True if we don't have a relevant authority OR if we are checking VMC AND Location
  return 1 unless $self->bimi_object->options->no_location_with_vmc;
  if ( $self->authority && $self->authority->is_relevant ) {
    warn 'Location is not relevant' if $self->bimi_object->options->verbose;
    return 0;
  }
  return 1;
}

sub _build_is_valid($self) {
  return 0 if ! keys $self->record->%*;

  if ( ! exists ( $self->record->{v} ) ) {
    $self->add_error( $self->ERR_MISSING_V_TAG );
    return 0;
  }
  else {
    $self->add_error( $self->ERR_EMPTY_V_TAG )   if lc $self->record->{v} eq '';
    $self->add_error( $self->ERR_INVALID_V_TAG ) if lc $self->record->{v} ne 'bimi1';
    return 0 if $self->error->@*;
  }
  if ($self->authority->is_relevant && !$self->authority->is_valid) {
    $self->add_error( $self->authority->error );
  }
  if ($self->location_is_relevant && !$self->location->is_valid) {
    $self->add_error( $self->location->error );
  }

  return 0 if $self->error->@*;

  if ( $self->bimi_object->options->require_vmc ) {
      unless ( $self->authority && $self->authority->vmc && $self->authority->vmc->is_valid ) {
          $self->add_error( $self->ERR_VMC_REQUIRED );
      }
  }

  if ( $self->authority && $self->authority->is_relevant ) {
    # Check the SVG payloads are identical
    ## Compare raw? or Uncompressed?
    if ( $self->location_is_relevant && $self->authority->vmc->indicator->data_uncompressed ne $self->location->indicator->data_uncompressed ) {
    #if ( $self->authority->vmc->indicator->data_maybe_compressed ne $self->location->indicator->data_maybe_compressed ) {
      $self->add_error( $self->ERR_SVG_MISMATCH );
    }
  }

  return 0 if $self->error->@*;
  warn 'Record is valid' if $self->bimi_object->options->verbose;
  return 1;
}

sub _build_record($self) {
  my $domain            = $self->domain;
  my $selector          = $self->selector;
  my $fallback_selector = 'default';
  my $fallback_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($domain);

  my @records;
  eval {
    @records = $self->_get_from_dns($selector,$domain);
    1;
  } || do {
    my $error = $@;
    $error =~ s/ at \/.*$//;
    $self->add_error($self->ERR_DNS_ERROR($error));
    return {};
  };

  @records = grep { $_ =~ /^v=bimi1;/i } @records;

  if ( !@records ) {
    if ( $domain eq $fallback_domain && $selector eq $fallback_selector ) {
      # nothing to fall back to
      $self->add_error( $self->ERR_NO_BIMI_RECORD );
      return {};
    }

    warn 'Trying fallback domain' if $self->bimi_object->options->verbose;
    my @records;
    eval {
      @records = $self->_get_from_dns($fallback_selector,$fallback_domain);
      1;
    } || do {
      my $error = $@;
      $error =~ s/ at \/.*$//;
      $self->add_error($self->ERR_DNS_ERROR($error));
      return {};
    };

    @records = grep { $_ =~ /^v=bimi1;/i } @records;

    if ( !@records ) {
      $self->add_error( $self->ERR_NO_BIMI_RECORD );
      return {};
    }
    elsif ( scalar @records > 1 ) {
      $self->add_error( $self->ERR_MULTI_BIMI_RECORD );
      return {};
    }
    else {
      # We have one record, let's use that.
      $self->domain($fallback_domain);
      $self->selector($fallback_selector);
      $self->retrieved_record($records[0]);
      return $self->_parse_record($records[0]);
    }
  }
  elsif ( scalar @records > 1 ) {
    $self->add_error( $self->ERR_MULTI_BIMI_RECORD );
    return {};
  }
  else {
    # We have one record, let's use that.
    $self->retrieved_record($records[0]);
    return $self->_parse_record($records[0]);
  }
}

sub _get_from_dns($self,$selector,$domain) {
  my @matches;
  if ($self->bimi_object->options->force_record) {
    warn 'Using fake record' if $self->bimi_object->options->verbose;
    push @matches, $self->bimi_object->options->force_record;
    return @matches;
  }
  my $res     = $self->bimi_object->resolver;
  my $query   = $res->query( "$selector._bimi.$domain", 'TXT' ) or do {
    return @matches;
  };
  for my $rr ( $query->answer ) {
    next if $rr->type ne 'TXT';
    push @matches, scalar $rr->txtdata;
  }
  return @matches;
}

sub _parse_record($self,$record) {
  my $data = {};
  my @parts = split ';', $record;
  foreach my $part ( @parts ) {
    $part =~ s/^ +//;
    $part =~ s/ +$//;
    my ( $key, $value ) = split '=', $part, 2;
    $key = lc $key;
    if ( exists $data->{ $key } ) {
      $self->add_error( $self->ERR_DUPLICATE_KEY );
    }
    if ( grep { $key eq $_ } ( qw{ v l a } ) ) {
      $data->{$key} = $value;
    }
  }
  return $data;
}

=method I<finish()>

Finish and clean up, write cache if enabled.

=cut

sub finish($self) {
  $self->authority->finish if $self->authority;
  $self->location->finish if $self->location;
  $self->_write_cache;
}

=method I<app_validate()>

Output human readable validation status of this object

=cut

sub app_validate($self) {
  say 'Record Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  $self->is_valid; # To set retrieved record and actual domain/selector
  say YELLOW.'  Record    : '.($self->retrieved_record//'-none-').RESET;
  if ($self->retrieved_record){
    say YELLOW.'  Version   '.WHITE.': '.CYAN.($self->version//'-none-').RESET;
    say YELLOW.'  Domain    '.WHITE.': '.CYAN.($self->domain//'-none-').RESET;
    say YELLOW.'  Selector  '.WHITE.': '.CYAN.($self->selector//'-none-').RESET;
    say YELLOW.'  Authority '.WHITE.': '.CYAN.($self->authority->authority//'-none-').RESET if $self->authority;
    say YELLOW.'  Location  '.WHITE.': '.CYAN.($self->location->location//'-none-').RESET if $self->location_is_relevant && $self->location;
    say YELLOW.'  Is Valid  '.WHITE.': '.($self->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  }

  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->error->@* ) {
      my $error_code = $error->code;
      my $error_text = $error->description;
      my $error_detail = $error->detail // '';
      $error_detail =~ s/\n/\n    /g;
      say BRIGHT_RED."  $error_code ".WHITE.': '.CYAN.$error_text.($error_detail?"\n    ".$error_detail:'').RESET;
    }
  }
}

1;
