#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Mikuregator;

my $c = Mikuregator->new;
$c->batch('AggregatorUpdated')->run;
