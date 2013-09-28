package CPANasium::Model::Aggregator;
use strict;
use warnings;
use utf8;
use Web::Query;
use Log::Minimal;
use File::Temp ();
use Module::CPANfile::Safe;
use Time::Piece qw(localtime gmtime);

my $URL = 'https://github.com/languages/Perl/updated';

use Mouse;

has json => ( is => 'ro' );
has db => ( is => 'ro' );
has ua => ( is => 'ro' );
has pithub => ( is => 'ro' );
has client_id => ( is => 'ro', isa => 'Str', required => 1 );
has client_secret => ( is => 'ro', isa => 'Str', required => 1 );
has pithub => (is => 'ro', required => 1);

no Mouse;

# @return ('miyagawa/CGI-Compile', 'tokuhirom/Amon', ...)
sub get_updated_repo_list {
    my ($self, $page) = @_;

    my $wq = wq($URL . ($page ? "?page=$page" : ''))->find('.repo-leaderboard-title a')->map(sub {
        my ($i, $elem) = @_;
        my $href = $elem->attr('href');
        $href =~ s!^/!!;
        $href;
    });
    unless (@$wq > 0) {
        warnf("%s has been changed", $URL);
    }
    return @$wq;
}

# @args $repo: 'miyagawa/CGI-Compile'
sub get_repo_info {
    my ($self, $repo) = @_;

    my $result = $self->pithub->request(
        method => 'GET',
        path   => sprintf( "/repos/%s", $repo ),
        params => {
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
        },
    );
    return $result;
}

# get_repo_list('users', 'miyagawa');
# get_repo_list('orgs', 'Plack');
sub get_repo_list {
    my ($self, $type, $github_id) = @_;

    my $result = $self->pithub->request(
        method => 'GET',
        path   => sprintf( "/%s/%s/repos", $type, $github_id ),
        params => {
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            type          => 'public',
            per_page      => 100000,
        },
    );
    $result->auto_pagination(1);
    $result;
}

# @args $time '2013-05-23T04:40:16Z'
sub parse_time {
    my ($self, $time) = @_;
    gmtime->strptime($time, '%Y-%m-%dT%H:%M:%SZ');
}

# @args $result: Pithub::Result
sub insert {
    my ($self, $result) = @_;

    infof("API: %d/%d",
        $result->response->header('X-RateLimit-Remaining'),
        $result->response->header('X-RateLimit-Limit'),
    );
    unless ( $result->success ) {
        warnf(
            "something is fishy:\n%s\n--\n%s\n--\n",
            $result->response->request->as_string,
            $result->response->as_string,
        );
        return;
    }

    while ( my $row = $result->next ) {
        next if $row->{private};
        next if $row->{fork};

        my $params = +{
            master_branch => $row->{master_branch},
            html_url      => $row->{html_url},
            name          => $row->{name},
            full_name     => $row->{full_name},
            owner_avatar_url => $row->{owner}->{avatar_url},
            'description' => $row->{description},
            forks         => $row->{forks},
            watchers      => $row->{watchers},
            owner_login   => $row->{owner}->{login},
            updated_at    => $self->parse_time($row->{updated_at})->epoch,
            created_at    => $self->parse_time($row->{created_at})->epoch,
        };
        my $cpanfile = sprintf 'https://raw.github.com/%s/master/cpanfile', $row->{full_name}, $row->{master_branch};
        infof("Fetching cpanfile from %s", $cpanfile);
        my $res = $self->ua->get($cpanfile);
        if ($res->is_success && $res->content !~ /<!DOCTYPE html>/) {
            infof("Got cpanfile");
            my $cpanfile = $res->content;
            $self->db->replace(
                repos => {
                    %$params,
                    data     => $self->json->encode($row),
                    cpanfile => $cpanfile,
                }
            );
            infof('%s', ddf($params));
            $self->analyze_cpanfile($row->{full_name}, $cpanfile);
        }
        ## $row->{watchers};
        ## $row->{master_branch};
        ## $row->{html_url};
        # use Data::Dumper; warn Dumper($row);
    }
}

sub analyze_cpanfile {
    my ($self, $full_name, $cpanfile) = @_;

    infof("Analyzing cpanfile for %s", $full_name);

    my $tmpfile = File::Temp->new(UNLINK => 1);
    print {$tmpfile} $cpanfile;

    my $safe = Module::CPANfile::Safe->load($tmpfile->filename);
    my $prereq_specs = $safe->prereq_specs;

    # {
    #     'runtime' => {
    #         'requires' => {
    #             'Mojolicious' => '3.80',
    #             'Moo' => 1,
    #             'WebService::Belkin::Wemo::Discover' => 0
    #         }
    #     }
    # };
    my $txn = $self->db->txn_scope;
    $self->db->delete(
        deps => {
            repos_full_name => $full_name,
        },
    );
    while (my ($phase, $x) = each %$prereq_specs) {
        while (my ($relationship, $y) = each %$x) {
            while (my ($module, $version) = each %$y) {
                $self->db->replace(
                    deps => {
                        repos_full_name => $full_name,
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

1;

