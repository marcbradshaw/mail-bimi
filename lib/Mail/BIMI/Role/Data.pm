package Mail::BIMI::Role::Data;
# ABSTRACT: Class to retrieve data files
# VERSION
use 5.20.0;
use Moo::Role;
use Mail::BIMI::Pragmas;

sub get_file_name($self,$file) {
  my $base_file = __FILE__;
  $base_file =~ s/\/Role\/Data.pm$/\/Data\/$file/;
  if ( ! -e $base_file ) {
    die "File $file is missing";
  }
  return $base_file;
}

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

