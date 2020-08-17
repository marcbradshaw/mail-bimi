package Mail::BIMI::CacheBackend::File;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Sereal qw{encode_sereal decode_sereal};

with 'Mail::BIMI::Role::CacheBackend';
has _cache_filename => ( is => 'ro', lazy => 1, builder => '_build_cache_filename' );

=head1 DESCRIPTION

Cache worker role for File storage

=cut

sub get_from_cache($self) {
  my $cache_file = $self->_cache_filename;
  return if !-e $cache_file;
  my $raw = scalar read_file($self->_cache_filename);
  my $value = eval{ decode_sereal($raw) };
  warn "Error reading from cache: $@" if $@;
  return $value;
}

sub put_to_cache($self,$data) {
  warn 'Writing '.(ref $self->parent).' to cache file '.$self->_cache_filename if $self->parent->bimi_object->options->verbose;
  my $sereal_data = eval{ encode_sereal($data) };
  warn "Error writing to cachce: $@" if $@;
  return unless $sereal_data;
  write_file($self->_cache_filename,{atomic=>1},$sereal_data);
}

sub delete_cache($self) {
  unlink $self->_cache_filename;
}

sub _build_cache_filename($self) {
  my $cache_dir = $self->parent->bimi_object->options->cache_file_directory;
  return $cache_dir.'mail-bimi-cache-'.$self->_cache_hash.'.cache';
}

1;

