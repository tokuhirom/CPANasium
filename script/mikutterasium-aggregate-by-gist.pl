#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Pod::Usage;

use CPANasium;

my $c = CPANasium->new;
$c->batch('AggregateByGist')->run(@ARGV);

__END__

=head1 SYNOPSIS

    ### args: $start_page $limit_page
    % cpanasium-aggregate-by-gist.pl 1 10

