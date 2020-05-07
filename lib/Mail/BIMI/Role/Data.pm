package Mail::BIMI::Role::Data;
# ABSTRACT: Class to retrieve data files
# VERSION
use 5.20.0;
use Moo::Role;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;

sub get_data_from_file($self,$file) {
  my $base_file = __FILE__;
  $base_file =~ s/\/Role\/Data.pm$/\/Data\/$file/;
  if ( ! -e $base_file ) {
    die "File $file is missing";
  }
  open my $data_file, '<', $base_file;
  my @content = <$data_file>;
  close $data_file;
  return join( q{}, @content );
}

1;

