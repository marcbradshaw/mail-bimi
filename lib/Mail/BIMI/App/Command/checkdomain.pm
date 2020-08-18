package Mail::BIMI::App::Command::checkdomain;
# ABSTRACT: Validate the BIMI assertion record for a given domain
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC;
use Term::ANSIColor qw{ :constants };

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checkdomain' command

=cut

sub description { 'Check the BIMI assertion record for a given domain' };
sub usage_desc { "%c checkdomain %o <DOMAIN>" }

sub opt_spec {
  return (
    [ 'profile=s', 'SVG Profile to validate against ('.join('|',@Mail::BIMI::Indicator::VALIDATOR_PROFILES).')' ],
    [ 'selector=s', 'Optional selector' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No Domain specified') if !@$args;
 $self->usage_error('Multiple Domains specified') if scalar @$args > 1;
 $self->usage_error('Unknown SVG Profile') if $opt->profile && !grep {;$_ eq $opt->profile} @Mail::BIMI::Indicator::VALIDATOR_PROFILES
}

sub execute($self,$opt,$args) {
  my $domain = $args->[0];
  my $selector = $opt->selector // 'default';

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->header_from($domain);
  $dmarc->validate;
  $dmarc->result->result('pass');
  my $bimi = Mail::BIMI->new(
    dmarc_object => $dmarc,
    domain => $domain,
    selector => $selector,
    options => {
      ( $opt->profile ? ( svg_profile => $opt->profile ) : () ),
    },
  );

  my $record = $bimi->record;
  #  my $record = Mail::BIMI::Record->new( domain => $domain, selector => $selector );
  say "BIMI domain checker";
  say '';
  say 'Requested:';
  say YELLOW.'  Domain    '.WHITE.': '.CYAN.$domain.RESET;
  say YELLOW.'  Selector  '.WHITE.': '.CYAN.$selector.RESET;
  say '';
  $record->app_validate;
  if ( $record->location && $record->location->indicator ) {
    say '';
    $record->location->indicator->app_validate;
  }
  if ( $record->authority && $record->authority->vmc ) {
    say '';
    $record->authority->vmc->app_validate;
    if ( $record->authority->vmc->indicator ) {
        say '';
        $record->authority->vmc->indicator->app_validate;
    }
  }
  say '';

  say 'An authenticated email with this record would receive the following BIMI results:';
  say '';
  my $result = $bimi->result;
  say "Authentication-Reults: authservid.example.com; ".$result->get_authentication_results;
  my $headers = $result->headers;
  foreach my $header ( sort keys $headers->%* ) {
      say "$header: ".$headers->{$header};
  }

  $bimi->finish;
}

1;

