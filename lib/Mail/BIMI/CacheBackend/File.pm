package Mail::BIMI::CacheBackend::File;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
use Digest::SHA256;
  with 'Mail::BIMI::Role::CacheBackend';
  has _cache_filename => ( is => 'ro', lazy => 1, builder => '_build_cache_filename' );

=head1 DESCRIPTION

Cache worker role for File storage

=cut

sub get_from_cache($self) {
  my $cache_file = $self->_cache_filename;
  return if !-e $cache_file;
  my $raw = read_file($self->_cache_filename);
  my $j = JSON->new;
  $self->parent->_cache_raw_data($raw);
  return eval{ $j->decode($raw) };
}

sub put_to_cache($self,$data) {
  my $j = JSON->new;
  warn 'Writing '.(ref $self->parent).' to cache' if $self->bimi_object->OPT_VERBOSE;
  $j->canonical;
  my $json_data = $j->encode($data);
  return if $self->parent->_cache_raw_data && $json_data eq $self->parent->_cache_raw_data;
  write_file($self->_cache_filename,{atomic=>1},$json_data);
}

sub delete_cache($self) {
  unlink $self->_cache_filename;
}

sub _build_cache_filename($self) {
  my $cache_dir = $self->bimi_object->OPT_CACHE_FILE_DIRECTORY // '/tmp/';
  my $context = Digest::SHA256::new(512);
  my $hash = $context->hexhash( $self->parent->_cache_key );
  $hash =~ s/ //g;
  return $cache_dir.'mail-bimi-cache-'.$hash.'.cache';
}

1;

