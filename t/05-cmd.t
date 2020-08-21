#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Test::More;
use Encode qw{encode};
use Mail::BIMI::Prelude;
use Mail::BIMI::App;
use App::Cmd::Tester;

my $write_data = 0; # Set to 1 to write new test data, then check it and commit

subtest 'checkdomain' => sub {

  subtest 'No Domain' => sub{
    my $file = 'app-checkdomain-nodomain';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain } ]);
    do_tests($result,$file);
  };

  subtest 'No Domain' => sub{
    my $file = 'app-checkdomain-fastmaildmarc';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain fastmaildmarc.com } ]);
    do_tests($result,$file);
  };

};

subtest 'checkrecord' => sub {

  subtest 'No Record' => sub{
    my $file = 'app-checkrecord-norecord';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkrecord } ]);
    do_tests($result,$file);
  };

  subtest 'Has (Bogus) Record' => sub{
    my $file = 'app-checkrecord-bogus';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', 'v=bimi1;l=http://bogus' ]);
    do_tests($result,$file);
  };

};

subtest 'checksvg' => sub {

  subtest 'No SVG' => sub{
    my $file = 'app-checksvg-nosvg';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checksvg } ]);
    do_tests($result,$file);
  };

  subtest 'Test SVG (File)' => sub{
    my $file = 'app-checksvg-file';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', '--fromfile', 't/data/FM-good.svg' ]);
    do_tests($result,$file);
  };

};

# TODO when we have test data checkvmc

sub do_tests{
  my ($result,$file) = @_;
  my $error = encode('UTF-8',$result->error//'');
  my $stderr = encode('UTF-8',$result->stderr//'');
  my $stdout = encode('UTF-8',$result->stdout//'');
  if ( $write_data ) {
    write_file('t/data/'.$file.'.error',{binmode=>':utf8:'},$result->error);
    write_file('t/data/'.$file.'.stderr',{binmode=>':utf8:'},$result->stderr);
    write_file('t/data/'.$file.'.stdout',{binmode=>':utf8:'},$result->stdout);
  }
  my $expected_error=scalar read_file('t/data/'.$file.'.error');
  my $expected_stderr=scalar read_file('t/data/'.$file.'.stderr');
  my $expected_stdout=scalar read_file('t/data/'.$file.'.stdout');
  is($error, $expected_error, 'No Exceptions as expected');
  is($stderr, $expected_stderr, 'STDERR as expected');
  is($stdout, $expected_stdout,'STDOUT as expected');
};

done_testing;

