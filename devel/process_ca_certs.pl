#!/usr/bin/env perl
use strict;
use warnings;

my $target = '../lib/Mail/BIMI/Data';

die "Are we in the correct directory" unless -f "$target/CA.manifest";

{
  opendir(my $dh, "$target/CA") || die "Can't opendir: $!";
  unlink glob "$target/CA/*.pem";
}

my @all_files;

opendir(my $dh, "ca_certs") || die "Can't opendir: $!";
my @files = sort glob "ca_certs/*.pem";
for my $file (@files) {
  process($file);
}
closedir $dh;

open my $outf, '>', "$target/CA.manifest" || die "Could not write manifest: $!";
print $outf join "\n", @all_files;
close $outf;

sub process {
  my $file = shift;
  print "Processing file: $file\n";

  my $data = `openssl x509 -in \"$file\" -text`;

  my $serial = '';
  my $name = '';

  my @lines = split(/\n/, $data);

  while (my $line = shift @lines) {
    if ($line =~ /Serial Number:$/) {
      $serial = shift @lines;
    }
    if ($line =~ /Issuer: /) {
      $name = $line;

    }
    last if $serial && $name;
  }
  #print "$serial -- $name\n";
  die unless $serial && $name;

  $serial =~ s/\s//g;
  $serial =~ s/://g;
  print "Serial: $serial\n";
  $name =~ s/.*Issuer:.*CN = //;
  $name =~ s/ /-/g;

  my $filename = "$serial-$name.pem";
  print "Filename: $filename\n";
  print "\n";

  open my $outf, '>', "$target/CA/$filename" || die "Could not write CA file: $!";
  print $outf $data;
  close $outf;

  push @all_files, $filename;
}
