package CPANasium::Batch::AggregateByGist;
use strict;
use warnings;
use utf8;
use Log::Minimal;

use Mouse;

has c => ( is => 'ro' );

no Mouse;

sub run {
    my ($self, @args) = @_;
    my ($offset, $limit) = @args;
    $offset ||= 1;
    $limit  ||= $offset + 5; # GistAPI limit is 60.

    my $aggregator = $self->c->model('GistAggregator');

    for my $page ($offset..$limit) {
        infof("---- Gist page %d ----\n", $page);
        my @repos = $aggregator->get_gist_list($page);
        for my $repo (@repos) {
            infof("Repo: %s", $repo);
            my $result = $aggregator->get_gist_info($repo);
            $aggregator->insert($result);
        }
    }
}

1;

