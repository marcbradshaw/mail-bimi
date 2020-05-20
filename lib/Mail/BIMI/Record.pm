package Mail::BIMI::Record;
# ABSTRACT: Class to model a BIMI record
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Mail::BIMI::Record::Authority;
use Mail::BIMI::Record::Location;
use Mail::DMARC::PurePerl;
  with 'Mail::BIMI::Role::Base';
  with 'Mail::BIMI::Role::Constants';
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::Resolver';
  with 'Mail::BIMI::Role::Cacheable';
  has domain => ( is => 'rw', isa => Str, required => 1, is_cache_key => 1 );
  has retrieved_record => ( is => 'rwp', is_cacheable => 1 );
  has selector => ( is => 'rw', isa => Str, is_cache_key => 1 );
  has version => ( is => 'rw', isa => Str, lazy => 1, builder => '_build_version', is_cacheable => 1 );
  has authority => ( is => 'rw', isa => class_type('Mail::BIMI::Record::Authority'), lazy => 1, builder => '_build_authority' );
  has location => ( is => 'rw', isa => class_type('Mail::BIMI::Record::Location'), lazy => 1, builder => '_build_location' );
  has record => ( is => 'rw', isa => HashRef, lazy => 1, builder => '_build_record', is_cacheable => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', is_cacheable => 1 );

sub cache_valid_for($self) { return 3600 }

sub _build_version($self) {
  my $version;
  if ( exists $self->record->{v} ) {
    $version = $self->record->{v} // '';
  }
  return $version;
}

sub _build_authority($self) {
  my $record;
  if ( exists $self->record->{a} ) {
    $record = $self->record->{a} // '';
  }
  # TODO better parser here
  return Mail::BIMI::Record::Authority->new( authority => $record, bimi_object => $self->bimi_object );
}

sub _build_location($self) {
  my $record;
  if ( exists $self->record->{l} ) {
    $record = $self->record->{l} // '';
  }
  # TODO better parser here
  # Need to decode , and ; as per spec>
  my $location = Mail::BIMI::Record::Location->new( location => $record, is_relevant => $self->location_is_relevant, bimi_object => $self->bimi_object );
  return $location;
}

sub location_is_relevant($self) {
  # True if we don't have a relevant authority OR if we are checking VMC AND Location
  return 1 unless $self->bimi_object->NO_LOCATION_WITH_VMC;
  warn $self->authority->is_relevant;
  if ( $self->authority && $self->authority->is_relevant ) {
    return 0;
  }
  return 1;
}

sub _build_is_valid($self) {
  return 0 if ! keys $self->record->%*;

  if ( ! exists ( $self->record->{v} ) ) {
    $self->add_error( $self->MISSING_V_TAG );
    return 0;
  }
  else {
    $self->add_error( $self->EMPTY_V_TAG )   if lc $self->record->{v} eq '';
    $self->add_error( $self->INVALID_V_TAG ) if lc $self->record->{v} ne 'bimi1';
    return 0 if $self->error->@*;
  }
  if (!$self->authority->is_valid) {
    $self->add_error( $self->authority->error );
  }
  if ($self->location_is_relevant && !$self->location->is_valid) {
    $self->add_error( $self->location->error );
  }

  return 0 if $self->error->@*;

  if ( $self->authority && $self->authority->is_relevant ) {
    # Check the SVG payloads are identical
    ## Compare raw? or Uncompressed?
    if ( $self->location_is_relevant && $self->authority->vmc->indicator->data_uncompressed ne $self->location->indicator->data_uncompressed ) {
    #if ( $self->authority->vmc->indicator->data_maybe_compressed ne $self->location->indicator->data_maybe_compressed ) {
      $self->add_error( $self->SVG_MISMATCH );
    }
  }

  return 0 if $self->error->@*;
  return 1;
}

sub _build_record($self) {
  my $domain            = $self->domain;
  my $selector          = $self->selector;
  my $fallback_selector = 'default';
  my $fallback_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($domain);

  my @records = grep { $_ =~ /^v=bimi1;/i } eval { $self->_get_from_dns($selector,$domain); };
  if ( my $error = $@ ) {
    $error =~ s/ at \/.*$//;
    $self->add_error({ error => $self->DNS_ERROR, detail => $error });
    return {};
  }

  if ( !@records ) {
    if ( $domain eq $fallback_domain && $selector eq $fallback_selector ) {
      # nothing to fall back to
      $self->add_error( $self->NO_BIMI_RECORD );
      return {};
    }

    @records = grep { $_ =~ /^v=bimi1;/i } eval { $self->_get_from_dns($fallback_selector,$fallback_domain); };
    if ( my $error = $@ ) {
      $error =~ s/ at \/.*$//;
      $self->add_error({ error => $self->DNS_ERROR, detail => $error });
      return {};
    }
    if ( !@records ) {
      $self->add_error( $self->NO_BIMI_RECORD );
      return {};
    }
    elsif ( scalar @records > 1 ) {
      $self->add_error( $self->MULTI_BIMI_RECORD );
      return {};
    }
    else {
      # We have one record, let's use that.
      $self->domain($fallback_domain);
      $self->selector($fallback_selector);
      $self->_set_retrieved_record($records[0]);
      return $self->_parse_record($records[0]);
    }
  }
  elsif ( scalar @records > 1 ) {
    $self->add_error( $self->MULTI_BIMI_RECORD );
    return {};
  }
  else {
    # We have one record, let's use that.
    $self->_set_retrieved_record($records[0]);
    return $self->_parse_record($records[0]);
  }
}

sub _get_from_dns($self,$selector,$domain) {
  my @matches;
  if ($self->bimi_object->FORCE_RECORD) {
    push @matches, $self->bimi_object->FORCE_RECORD;
    return @matches;
  }
  my $res     = $self->resolver;
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
      $self->add_error( $self->DUPLICATE_KEY );
    }
    if ( grep { $key eq $_ } ( qw{ v l a } ) ) {
      $data->{$key} = $value;
    }
  }
  return $data;
}

sub app_validate($self) {
  say 'Record Returned:';
  $self->is_valid; # To set retrieved record and actual domain/selector
  say '  Record    : '.($self->retrieved_record//'-none-');
  if ($self->retrieved_record){
    say '  Version   : '.($self->version//'-none-');
    say '  Domain    : '.($self->domain//'-none-');
    say '  Selector  : '.($self->selector//'-none-');
    say '  Authority : '.($self->authority->authority//'-none-') if $self->authority;
    say '  Location  : '.($self->location->location//'-none-') if $self->location_is_relevant && $self->location;
    say '  Is Valid  : '.($self->is_valid?'Yes':'No');
  }

  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->error_detail->@* ) {
      my $error_text = $error->{error};
      my $error_detail = $error->{detail};
      $error_detail =~ s/\n/\n    /g;
      say "  $error_text".($error_detail?"\n    ".$error_detail:'');
    }
  }
}

1;
