#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Mail::BIMI;
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
my $bimi = Mail::BIMI->new(domain=>'example.com');
$bimi->resolver($resolver);

subtest 'No errors' => sub{
  is_deeply($bimi->serialize_error,[],'Empty ArrayRef');
};

my $serialized;

subtest 'Has error' => sub{
  $bimi->add_error('NO_DMARC');
  is_deeply($bimi->serialize_error,[{code=>'NO_DMARC',detail=>undef}],'Single Entry');
  $bimi->add_error('DNS_ERROR','FooBar');
  is_deeply($bimi->serialize_error,[{code=>'NO_DMARC',detail=>undef},{code=>'DNS_ERROR',detail=>'FooBar'}],'Multi Entry');
  $serialized = $bimi->serialize_error;
};

subtest 'Deserialize' => sub {
  my $bimi2 = Mail::BIMI->new(domain=>'example.com');
  $bimi2->deserialize_error($serialized);
  is(scalar $bimi2->error->@*, 2, '2 Errors added');
  subtest 'First Error' => sub {
    is(ref $bimi2->error->[0],'Mail::BIMI::Error','Is Error Object');
    is($bimi2->error->[0]->code,'NO_DMARC','Corrrect code');
    is($bimi2->error->[0]->detail,undef,'Corrrect detail');
  };
  subtest 'Second Error' => sub {
    is(ref $bimi2->error->[1],'Mail::BIMI::Error','Is Error Object');
    is($bimi2->error->[1]->code,'DNS_ERROR','Corrrect code');
    is($bimi2->error->[1]->detail,'FooBar','Corrrect detail');
  };
};

done_testing;
