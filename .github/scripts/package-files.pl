#!/usr/bin/env perl
# Reads file paths (one per line, relative to the package root) and prints
# those that R CMD build would put in the package. R drops a path when a
# .Rbuildignore pattern matches it or any directory above it, matching
# case-insensitively with Perl regular expressions, as this does.
use strict;
use warnings;

open my $fh, '<', '.Rbuildignore' or die "no .Rbuildignore: $!";
my @ignore = grep { /\S/ } map { s/\s+$//r } <$fh>;
close $fh;

PATH: while (my $path = <STDIN>) {
  chomp $path;
  next unless length $path;
  my @parts = split m{/}, $path;
  for my $i (0 .. $#parts) {
    my $prefix = join '/', @parts[0 .. $i];
    for my $re (@ignore) {
      next PATH if $prefix =~ /$re/i;
    }
  }
  print "$path\n";
}
