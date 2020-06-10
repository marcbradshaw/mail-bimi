package Mail::BIMI::Error;
# ABSTRACT: Class to represent an error condition
# VERSION
use 5.20.0;
use Moo;
use Mail::BIMI::Pragmas;
  has code => ( is => 'ro', isa => Str, required => 1,
    documentation => 'Error code', pod_section => 'inputs' );
  has description => ( is => 'ro', isa => Str, required => 1,
    documentation => 'Human readable error descriptionn', pod_section => 'inputs' );
  has detail => ( is => 'ro', isa => Str, required => 0,
    documentation => 'Human readable details', pod_section => 'inputs' );

=head1 DESCRIPTION

Class for representing an error condition

=cut

1;
