package Mail::BIMI::App::Command::checksvg;
# ABSTRACT: Check an SVG for validation
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use Mail::BIMI::Pragmas;
use Mail::BIMI::App -command;
use Mail::BIMI::Indicator;

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checksvg' command

=cut

sub abstract { 'Validate a given SVG by url' }
sub description { 'Mail::BIMI SVG validator' };
sub usage_desc { "%c checksvg %o <URL>" }

sub opt_spec {
  return (
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No URL specified') if !@$args;
 $self->usage_error('Multiple URLs specified') if scalar @$args > 1;
}

sub execute($self,$opt,$args) {
  require Mail::BIMI::Indicator;
  my $url = $args->[0];
  my $indicator = Mail::BIMI::Indicator->new( location => $url );
  say "BIMI SVG checker";
  say '';
  say 'Requested:';
  say "URL : $url";
  say '';
  $indicator->app_validate;
  say '';
}

1;

