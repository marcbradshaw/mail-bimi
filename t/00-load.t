#!perl -T
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Test::More;

BEGIN {

  foreach my $module (qw{
    Mail::BIMI
    Mail::BIMI::App
    Mail::BIMI::App::Command::checkdomain
    Mail::BIMI::App::Command::checkrecord
    Mail::BIMI::App::Command::checksvg
    Mail::BIMI::App::Command::checkvmc
    Mail::BIMI::Base
    Mail::BIMI::CacheBackend::FastMmap
    Mail::BIMI::CacheBackend::File
    Mail::BIMI::CacheBackend::Null
    Mail::BIMI::Error
    Mail::BIMI::Indicator
    Mail::BIMI::Options
    Mail::BIMI::Prelude
    Mail::BIMI::Record
    Mail::BIMI::Record::Authority
    Mail::BIMI::Record::Location
    Mail::BIMI::Result
    Mail::BIMI::Role::CacheBackend
    Mail::BIMI::Role::Cacheable
    Mail::BIMI::Role::Data
    Mail::BIMI::Role::HasError
    Mail::BIMI::Role::HasHTTPClient
    Mail::BIMI::VMC
    Mail::BIMI::VMC::Cert
    Mail::BIMI::VMC::Chain
  }) {
    use_ok( $module ) || print "Bail out!^@";
  }

}

my $version = $Mail::BIMI::VERSION || '[HEAD]';
diag("Testing Mail::BIMI $version, Perl $], $^X");

done_testing;
