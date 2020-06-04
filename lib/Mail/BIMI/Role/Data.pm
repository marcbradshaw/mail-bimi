package Mail::BIMI::Role::Data;
# ABSTRACT: Class to retrieve data files
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;

=head1 DESCRIPTION

Role for classes which require access to locally packaged files

=cut

=method I<get_file_name($file)>

Returns the full path and filename for included file $file

=cut

sub get_file_name($self,$file) {
  my $base_file = __FILE__;
  $base_file =~ s/\/Role\/Data.pm$/\/Data\/$file/;
  if ( ! -e $base_file ) {
    die "File $file is missing";
  }
  return $base_file;
}

=method I<get_data_from_file($file)>

Returns the contents of included file $file

=cut

sub get_data_from_file($self,$file) {
  my $base_file = __FILE__;
  $base_file =~ s/\/Role\/Data.pm$/\/Data\/$file/;
  if ( ! -e $base_file ) {
    die "File $file is missing";
  }
  my $body = read_file($base_file);
  return $body;
}

1;

