package Mail::BIMI::Error;
# ABSTRACT: Class to represent an error condition
# VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

has code => ( is => 'ro', isa => Str, required => 1,
  documentation => 'inputs: Error code', );
has description => ( is => 'ro', isa => Str, required => 1,
  documentation => 'inputs: Human readable error descriptionn', );
has detail => ( is => 'ro', isa => Str, required => 0,
  documentation => 'inputs: Human readable details', );

=head1 DESCRIPTION

Class for representing an error condition

=cut

1;
