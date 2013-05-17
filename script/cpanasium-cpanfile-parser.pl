#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Pod::Usage;

use CPANasium;

my $c = CPANasium->bootstrap;
$c->batch('CPANFileParser')->run();

__END__

=head1 SYNOPSIS

    % cpanasium-parser.pl

