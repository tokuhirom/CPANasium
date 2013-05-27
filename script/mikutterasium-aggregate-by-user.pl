#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Pod::Usage;

use CPANasium;

my $c = CPANasium->new;
$c->batch('AggregateByUser')->run(@ARGV);

__END__

=head1 SYNOPSIS

    % cpanasium-aggregate-by-user.pl tokuhirom

