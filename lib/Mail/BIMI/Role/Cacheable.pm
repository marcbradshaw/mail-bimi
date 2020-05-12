package Mail::BIMI::Role::Cacheable;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;
  my $backend = $ENV{MAIL_BIMI_CACHE_BACKEND} // 'File';
  my $cache_backend = $backend eq 'File' ? 'File'
                    : $backend eq 'Null' ? 'Null'
                    : 'Null'; # Untaint
  with  'Mail::BIMI::Role::Cacheable::'.$cache_backend;

  has _do_not_cache => ( is => 'rw', isa => Int, required => 0 );
  has _cache_read_timestamp => ( is => 'rw', required => 0 );
  has _cache_raw_data => ( is => 'rw', required => 0);
  has _cache_key => ( is => 'rw' );
  has _cache_fields => ( is => 'rw' );
  requires 'cache_valid_for';

sub do_not_cache($self) {
  $self->_do_not_cache(1);
}

sub BUILD($self,$args) {
  my @cache_key;
  my @cache_fields;
  foreach my $attribute ( sort keys %{Moo->_constructor_maker_for(ref $self)}{attribute_specs}->%* ) {
    my $this_attribute = %{Moo->_constructor_maker_for(ref $self)}{attribute_specs}->{$attribute};
    if ( $this_attribute->{is_cacheable} && $this_attribute->{is_cache_key}) {
      croak "Attribute $attribute cannot be BOTH is_cacheable AND is_cache_key";
    }
    elsif ( $this_attribute->{is_cache_key} ) {
      push @cache_key, "$attribute=".$self->{$attribute};
    }
    elsif ( $this_attribute->{is_cacheable} ) {
      push @cache_fields, $attribute;
    }
  }

  croak "No cache key defined" if ! @cache_key;
  croak "No cacheable fields defined" if ! @cache_fields;

  $self->_cache_key( join("\n",
    ref $self,
    @cache_key,
  ));
  $self->_cache_fields( \@cache_fields );

  my $data = $self->_get_from_cache;
  return if !$data;

  return if $data->{cache_key} ne $self->_cache_key;
  if ($data->{timestamp}+$self->cache_valid_for < time) {
    $self->_delete_cache;
    return;
  }

  $self->_cache_read_timestamp($data->{timestamp});
  foreach my $cache_field ( $self->_cache_fields->@* ) {
    if ( exists ( $data->{data}->{$cache_field} )) {
      $self->{$cache_field} = $data->{data}->{$cache_field};
    }
  }

}

sub DEMOLISH($self,$in_global_destruction) {
  return if $self->_do_not_cache;
  my $data = {
    cache_key => $self->_cache_key,
    timestamp => $self->_cache_read_timestamp // time,
    data => {},
  };
  foreach my $cache_field ( $self->_cache_fields->@* ) {
    if ( defined ( $self->{$cache_field} )) {
      $data->{data}->{$cache_field} = $self->{$cache_field};
    }
  }

  $self->_put_to_cache($data);
}

sub _build_cache_filename($self) {
  my $cache_dir = '/tmp/';
  my $context = Digest::SHA256::new(512);
  my $hash = $context->hexhash( $self->_cache_key );
  $hash =~ s/ //g;
  return $cache_dir.'mail-bimi-cache-'.$hash.'.cache';
}

1;
