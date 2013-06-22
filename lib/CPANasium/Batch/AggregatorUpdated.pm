package CPANasium::Batch::AggregatorUpdated;
use strict;
use warnings;
use utf8;
use Log::Minimal;

use Mouse;

has c => ( is => 'ro' );

no Mouse;

sub run {
    my ($self) = @_;
    my $aggregator = $self->c->model('Aggregator');

    for my $page (1..50) {
        infof("---- page %d ----\n", $page);
        my @repos = $aggregator->get_updated_repo_list(
            $page
        );
        last unless @repos;
        for my $repo (@repos) {
            infof("Repo: %s", $repo);
            my $result = $aggregator->get_repo_info($repo);
            $aggregator->insert($result);
            sleep 2;
        }
    }

}

1;

