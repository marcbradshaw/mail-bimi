#!perl -T
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use Mail::BIMI::Pragmas;
use Test::More;

BEGIN {

  foreach my $module (qw{
    Mail::BIMI
    Mail::BIMI::App
    Mail::BIMI::App::Command::checkdomain
    Mail::BIMI::App::Command::checkrecord
    Mail::BIMI::App::Command::checksvg
    Mail::BIMI::App::Command::checkvmc
    Mail::BIMI::CacheBackend::FastMmap
    Mail::BIMI::CacheBackend::File
    Mail::BIMI::CacheBackend::Null
    Mail::BIMI::Error
    Mail::BIMI::Indicator
    Mail::BIMI::Pragmas
    Mail::BIMI::Record
    Mail::BIMI::Record::Authority
    Mail::BIMI::Record::Location
    Mail::BIMI::Result
    Mail::BIMI::Role::Base
    Mail::BIMI::Role::CacheBackend
    Mail::BIMI::Role::Cacheable
    Mail::BIMI::Role::Data
    Mail::BIMI::Role::Error
    Mail::BIMI::Role::HTTPClient
    Mail::BIMI::Role::Options
    Mail::BIMI::Role::Resolver
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
