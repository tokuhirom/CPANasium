package CPANasium::Batch::AggregateByUser;
use strict;
use warnings;
use utf8;
use Pod::Usage;

use Mouse;

has c => ( is => 'ro', required => 1 );

no Mouse;

sub run {
    my ($self, @args) = @_;

    my $user = shift @args or pod2usage(1);

    my $aggregator = $self->c->model('Aggregator');
    my $result = $aggregator->get_repo_list('users', $user);
    $aggregator->insert($result);
}

1;

