package Mail::BIMI::Role::Cacheable::File;
# ABSTRACT: Cache handling
# VERSION
use 5.20.0;
use Moo::Role;
use Carp;
use Types::Standard qw{Int};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
use JSON;
use Digest::SHA256;
  has _cache_filename => ( is => 'ro', lazy => 1, builder => '_build_cache_filename' );

sub _get_from_cache($self) {
  my $cache_file = $self->_cache_filename;
  return if !-e $cache_file;
  open my $inf,'<',$self->_cache_filename;
  my @all = <$inf>;
  close $inf;
  my $j = JSON->new;
  my $raw = join('',@all);
  $self->_cache_raw_data($raw);
  return eval{ $j->decode($raw) };
}

sub _put_to_cache($self,$data) {
  my $j = JSON->new;
  $j->canonical;
  my $json_data = $j->encode($data);
  return if $self->_cache_raw_data && $json_data eq $self->_cache_raw_data;
  open my $outf,'>',$self->_cache_filename;
  print $outf $json_data;
  close $outf;
}

sub _delete_cache($self) {
  unlink $self->_cache_filename;
}

1;

