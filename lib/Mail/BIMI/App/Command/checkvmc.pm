package Mail::BIMI::App::Command::checkvmc;
# ABSTRACT: Check an VMC for validation
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Indicator;
use Mail::BIMI::VMC;
use Term::ANSIColor qw{ :constants };

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checksvg' command

=cut

sub description { 'Check a VMC from a given URI or File for validity' }
sub usage_desc { "%c checksvg %o <URI>" }

sub opt_spec {
  return (
    [ 'profile=s', 'SVG Profile to validate against ('.join('|',@Mail::BIMI::Indicator::VALIDATOR_PROFILES).')' ],
    [ 'domain=s', 'Domain' ],
    [ 'fromfile', 'Fetch from file instead of from URI' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No URI specified') if !@$args;
 $self->usage_error('Multiple URIs specified') if scalar @$args > 1;
 $self->usage_error('Unknown SVG Profile') if $opt->profile && !grep {;$_ eq $opt->profile} @Mail::BIMI::Indicator::VALIDATOR_PROFILES;
}

sub execute($self,$opt,$args) {
  my $uri = $args->[0];

  my %bimi_opt;
  if ( $opt->domain ) {
    $bimi_opt{domain} = $opt->domain;
  }
  else {
    $bimi_opt{domain} = 'example.com';
  }
  $bimi_opt{options} = {};
  $bimi_opt{options}->{vmc_no_check_alt} = 1 if !$opt->domain;
  $bimi_opt{options}->{vmc_from_file} = $uri if $opt->fromfile;

  my $bimi = Mail::BIMI->new(%bimi_opt);

  my $vmc = Mail::BIMI::VMC->new( check_domain => $opt->domain//'', uri => $uri, bimi_object => $bimi );
  #  $indicator->validator_profile($opt->profile) if $opt->profile;
  say "BIMI VMC checker";
  say '';
  say 'Requested:';
  say YELLOW.($opt->fromfile?'File':'URI').WHITE.': '.$uri.RESET;
  say '';
  $vmc->app_validate;
  say '';
  if ( $vmc->indicator ) {
    $vmc->indicator->app_validate;
    say '';
  }

  $bimi->finish;
}

1;

