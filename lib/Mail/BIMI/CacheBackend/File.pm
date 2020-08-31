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

=method I<get_from_cache()>

Retrieve this class data from cache

=cut

sub get_from_cache($self) {
  my $cache_file = $self->_cache_filename;
  return if !-e $cache_file;
  my $raw = scalar read_file($self->_cache_filename);
  my $value = eval{ decode_sereal($raw) };
  warn "Error reading from cache: $@" if $@;
  return $value;
}

=method I<put_to_cache($data)>

Put this classes data into the cache

=cut

sub put_to_cache($self,$data) {
  $self->parent->log_verbose('Writing '.(ref $self->parent).' to cache file '.$self->_cache_filename);
  my $sereal_data = eval{ encode_sereal($data) };
  warn "Error writing to cache: $@" if $@; # uncoverable branch
  return unless $sereal_data; # uncoverable branch
  write_file($self->_cache_filename,{atomic=>1},$sereal_data);
}

=method I<delete_cache>

Delete the cache entry for this class

=cut

sub delete_cache($self) {
  unlink $self->_cache_filename or warn "Unable to unlink cache file: $!";
}

sub _build_cache_filename($self) {
  my $cache_dir = $self->parent->bimi_object->options->cache_file_directory;
  return $cache_dir.'mail-bimi-cache-'.$self->_cache_hash.'.cache';
}

1;

