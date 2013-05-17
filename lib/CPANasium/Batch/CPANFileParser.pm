package CPANasium::Batch::CPANFileParser;
use strict;
use warnings;
use utf8;
use Module::CPANfile::Safe;

use Mouse;

has db => (
    is => 'ro',
    required => 1,
);

no Mouse;

sub run {
    my $self = shift;
    my $iter = $self->db->search('repos');
    while (my $repos = $iter->next) {
        my $src = $repos->cpanfile;
        next if $src =~ /<!DOCTYPE html>/;

        my $cpanfile = Module::CPANfile::Safe->load_from_string($src);
        my $prereq_specs = $cpanfile->prereq_specs;

        # {
        #     'runtime' => {
        #         'requires' => {
        #             'Mojolicious' => '3.80',
        #             'Moo' => 1,
        #             'WebService::Belkin::Wemo::Discover' => 0
        #         }
        #     }
        # };
        # TODO: bulk insert
        my $txn = $self->db->txn_scope;
        while (my ($phase, $x) = each %$prereq_specs) {
            while (my ($relationship, $y) = each %$x) {
                while (my ($module, $version) = each %$y) {
                    $self->db->replace(
                        deps => {
                            repos_full_name => $repos->full_name,
                            phase => $phase,
                            relationship => $relationship,
                            module => $module,
                            version => $version,
                        },
                    );
                }
            }
        }
        $txn->commit;
    }
}

1;

