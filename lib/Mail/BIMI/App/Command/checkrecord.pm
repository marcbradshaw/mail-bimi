package Mail::BIMI::App::Command::checkrecord;
# ABSTRACT: Check a BIMI record for validation
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use Mail::BIMI::Pragmas;
use Mail::BIMI::App -command;
use Mail::BIMI::Record;

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checkrecord' command

=cut

sub abstract { 'Validate a given BIMI record' }
sub description { 'Mail::BIMI record validator' };
sub usage_desc { "%c checkrecord %o <DOMAIN>" }

sub opt_spec {
  return (
    [ 'selector=s', 'Optional selector' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No Domain specified') if !@$args;
 $self->usage_error('Multiple Domains specified') if scalar @$args > 1;

}

sub execute($self,$opt,$args) {
  my $domain = $args->[0];
  my $selector = $opt->selector // 'default';
  my $record = Mail::BIMI::Record->new( domain => $domain, selector => $selector );
  say "BIMI record checker";
  say '';
  say 'Requested:';
  say "  Domain    : $domain";
  say "  Selector  : $selector";
  say '';
  $record->app_validate;
  if ( $record->location && $record->location->indicator ) {
    say '';
    $record->location->indicator->app_validate;
  }
  say '';
}

1;

