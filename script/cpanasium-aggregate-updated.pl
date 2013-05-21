#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use CPANasium;

my $c = CPANasium->new;
$c->batch('AggregatorUpdated')->run;
