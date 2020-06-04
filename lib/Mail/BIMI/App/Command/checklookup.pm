package Mail::BIMI::App::Command::checklookup;
# ABSTRACT: Check a domain for BIMI
# VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use Mail::BIMI::Pragmas;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC;

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checkrecord' command

=cut

sub abstract { 'Validate a given BIMI domain' }
sub description { 'Mail::BIMI domain validator' };
sub usage_desc { "%c checklookup %o <DOMAIN>" }

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

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->header_from($domain);
  $dmarc->validate;
  my $bimi = Mail::BIMI->new(
    dmarc_object => $dmarc,
    domain => $domain,
    selector => $selector,
  );

  say 'An authenticated email with this record would receive the following BIMI results:';
  say '';
  my $result = $bimi->result;
  say "Authentication-Reults: authservid.example.com; ".$result->get_authentication_results;
  my $headers = $result->headers;
  foreach my $header ( sort keys $headers->%* ) {
      say "$header: ".$headers->{$header};
  }

}

1;

