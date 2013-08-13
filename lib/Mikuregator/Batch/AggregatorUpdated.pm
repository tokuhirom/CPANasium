package Mikuregator::Batch::AggregatorUpdated;
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
        my $res = $aggregator->get_updated_repo_list(
            $page
        );
        last unless $res->is_success;
        my $content = $self->c->json->decode($res->content);
        for my $repo(@{$content->{repositories}}) {
            my $full_name = "$repo->{owner}/$repo->{name}";
            my $row = $self->c->db->single('repos', {full_name => $full_name});
            my $row_data = $row->{row_data};

            my $updated_at = $aggregator->parse_time($repo->{pushed_at})->epoch;
            next if ($row_data && $updated_at eq $row_data->{updated_at});

            my $result = $aggregator->get_repo_info($full_name);
            infof("Repo: %s", $repo);
            $aggregator->insert($result);
            sleep 5;
        }
    }

}

1;

