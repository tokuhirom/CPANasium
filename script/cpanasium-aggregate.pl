#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Pod::Usage;

use CPANasium;

@ARGV==2 or pod2usage(1);
my ($type, $name) = @ARGV;

my $c = CPANasium->bootstrap;
$c->aggregator->aggregate($type, $name);

__END__

=head1 SYNOPSIS

    % cpanasium-aggregate.pl user tokuhirom

