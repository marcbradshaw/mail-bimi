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
  dies_ok(sub{my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi)}, 'Dies');
};

subtest 'empty authority' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi, uri=>'');
  is($authority->is_valid, 1, 'Is valid');
  is($authority->is_relevant, 0, 'Is not relevant');
  is_deeply($authority->error_codes, [], 'No error codes');
};

subtest 'invalid authority transport' => sub {
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi, uri=>'http://example.com/foo.pem');
  is($authority->is_valid, 0, 'Is not valid');
  is($authority->is_relevant, 1, 'Is relevant');
  is_deeply($authority->error_codes, ['INVALID_TRANSPORT_A'], 'Error codes');
};

subtest 'self authority' => sub {
  # Not strictly to spec, but seen in the wild
  my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi, uri=>'self');
  is($authority->is_valid, 1, 'Is valid');
  is($authority->is_relevant, 0, 'Is not relevant');
  is_deeply($authority->error_codes, [], 'No error codes');
};

# TODO VMC Testing
sub vmc_subject_parse($name, $subject_string, $expected_result) {
  subtest "vmc subject parsing - $name" => sub {
  $bimi->domain('test.com');
    my $vmc = Mail::BIMI::VMC->new(bimi_object => $bimi, check_domain => 'test.com', check_selector => "");
    is ( $bimi->domain, 'test.com', 'set bimi domain' );
    my $subject_entries = $vmc->subject_entries($subject_string);
    is_deeply($subject_entries,$expected_result, 'subject entries parsed OK');
  };
}

vmc_subject_parse(
  'clean',
  'a=1, bn=2, a=3',
  {
    'bn' => ['2'],
    'a' =>  ['1', '3']
  },
);

vmc_subject_parse(
  'extra commas',
  'a=1,23, bn=2,3,4, a=3',
  {
    'bn' => ['2,3,4'],
    'a' =>  ['1,23', '3']
  },
);

vmc_subject_parse(
  'extra equals',
  'a=1,23, bn=2=3,4, a=3',
  {
    'bn' => ['2=3,4'],
    'a' =>  ['1,23', '3']
  },
);

vmc_subject_parse(
  'empty',
  '',
  {
  },
);

vmc_subject_parse(
  'just equals',
  '====',
  {
  },
);

vmc_subject_parse(
  'just commas',
  ',,,,',
  {
  },
);

vmc_subject_parse(
  'garbage',
  'well this is not what I expected to find in this string',
  {
  },
);

done_testing;
