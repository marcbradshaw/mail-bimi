package Mail::BIMI::App::Command::checksvg;
# ABSTRACT: Check an SVG for validation
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Pragmas;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Indicator;

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checksvg' command

=cut

sub abstract { 'Validate a given SVG by url' }
sub description { 'Mail::BIMI SVG validator' };
sub usage_desc { "%c checksvg %o <URL>" }

sub opt_spec {
  return (
    [ 'profile=s', 'SVG Profile to validate against ('.join('|',@Mail::BIMI::Indicator::VALIDATOR_PROFILES).')' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No URL specified') if !@$args;
 $self->usage_error('Multiple URLs specified') if scalar @$args > 1;
 $self->usage_error('Unknown SVG Profile') if $opt->profile && !grep {$opt->profile} @Mail::BIMI::Indicator::VALIDATOR_PROFILES
}

sub execute($self,$opt,$args) {
  my $url = $args->[0];
  my $bimi = Mail::BIMI->new;
  my $indicator = Mail::BIMI::Indicator->new( location => $url, bimi_object => $bimi );
  $indicator->validator_profile($opt->profile) if $opt->profile;
  say "BIMI SVG checker";
  say '';
  say 'Requested:';
  say "URL : $url";
  say '';
  $indicator->app_validate;
  say '';

  $bimi->finish;
}

1;

