#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Test::Exception;
use Mail::BIMI;
use Mail::BIMI::Record::Authority;
use Mail::BIMI::VMC;
my $bimi = Mail::BIMI->new(domain=>'example.com');

subtest 'missing authority' => sub {
  dies_ok(sub{my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi)},'Dies');
};

subtest 'empty authority' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'');
  is($authority->is_valid,1,'Is valid');
  is($authority->is_relevant,0,'Is not relevant');
  is_deeply($authority->error_codes,[],'No error codes');
};

subtest 'invalid authority transport' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'http://example.com/foo.pem');
  is($authority->is_valid,0,'Is not valid');
  is($authority->is_relevant,1,'Is relevant');
  is_deeply($authority->error_codes,['INVALID_TRANSPORT_A'],'Error codes');
};

subtest 'invalid authority extension' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'https://example.com/vmc.txt');
  is($authority->is_valid,0,'Is not valid');
  is($authority->is_relevant,1,'Is relevant');
  my @error_search = grep { $_->code eq 'INVALID_EXTENSION_A' && $_->detail eq 'VMC MUST have .pem extension'} $authority->errors->@*;
  is(scalar @error_search, 1, 'Expected error found' );
};

subtest 'valid authority extension' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'https://fastmaildmarc.com/bimi_test/vmc.pem');
  is($authority->is_valid,0,'Is not valid');
  is($authority->is_relevant,1,'Is relevant');
  my @error_search = grep { $_->code eq 'INVALID_EXTENSION_A' && $_->detail eq 'VMC MUST have .pem extension'} $authority->errors->@*;
  is(scalar @error_search, 0, 'Error not found' );
};

subtest 'valid authority extension UPPER' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'https://fastmaildmarc.com/bimi_test/vmc.PEM');
  is($authority->is_valid,0,'Is not valid');
  is($authority->is_relevant,1,'Is relevant');
  my @error_search = grep { $_->code eq 'INVALID_EXTENSION_A' && $_->detail eq 'VMC MUST have .pem extension'} $authority->errors->@*;
  is(scalar @error_search, 0, 'Error not found' );
};

subtest 'valid authority extension with params' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'https://fastmaildmarc.com/bimi_test/vmc.pem?foo=bar');
  is($authority->is_valid,0,'Is not valid');
  is($authority->is_relevant,1,'Is relevant');
  my @error_search = grep { $_->code eq 'VMC_FETCH_ERROR' && $_->detail eq 'VMC MUST have .pem extension'} $authority->errors->@*;
  is(scalar @error_search, 0, 'Error not found' );
};

subtest 'self authority' => sub {
  # Not strictly to spec, but seen in the wild
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'self');
  is($authority->is_valid,1,'Is valid');
  is($authority->is_relevant,0,'Is not relevant');
  is_deeply($authority->error_codes,[],'No error codes');
};

# TODO VMC Testing

done_testing;
