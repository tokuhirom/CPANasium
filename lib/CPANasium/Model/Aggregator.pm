package CPANasium::Model::Aggregator;
use strict;
use warnings;
use utf8;
use Web::Query;
use Log::Minimal;
use File::Temp ();
use Module::CPANfile::Safe;
use Time::Piece qw(localtime gmtime);
use JSON;
use LWP::UserAgent;
use Encode;
use Encode::Guess;

my $URL = 'https://api.github.com/legacy/repos/search/mikutter%20OR%20%22%E3%81%BF%E3%81%8F%E3%81%A3%E3%81%9F%22'; # mikutter OR "みくった"

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

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get($URL . '?sort=updated&start_page=' . $page);

    infof("API: %d/%d",
        $res->header('X-RateLimit-Remaining'),
        $res->header('X-RateLimit-Limit'),
    );

    unless ($res->is_success) {
        warnf(
            "something is fishy:\n%s\n--\n%s\n--\n",
            $res->request->as_string,
            $res->as_string,
        );
    }

    return $res;
}

# get_repo_list('users', 'miyagawa');

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

        my $data = $self->json->encode($row);
        my $repo_class = "";
        for my$_data ($data, $row->{html_url}, $row->{full_name}, $row->{description}) {
            $repo_class = "plugin" if $_data =~ m/(plugin)|(プラグイン)|(ﾌﾟﾗｸﾞｲﾝ)/i;
        }

        my $params = +{
            master_branch => $row->{master_branch},
            html_url      => $row->{html_url},
            name          => $row->{name},
            full_name     => $row->{full_name},
            owner_avatar_url => $row->{owner}->{avatar_url},
            'description' => $self->decode($row->{description}),
            forks         => $row->{forks},
            watchers      => $row->{watchers} || '',
            owner_login   => $row->{owner}->{login},
            updated_at    => $self->parse_time($row->{pushed_at})->epoch,
            created_at    => $self->parse_time($row->{created_at})->epoch,
            host_type     => 'github',
            repo_class    => $repo_class,
        };
        my $r = $self->db->replace(
            repos => {
                %$params,
                data     => $data,
                cpanfile => '', #$cpanfile,
            }
        );
        infof('%s', ddf($params));
        ## $row->{watchers};
        ## $row->{master_branch};
        ## $row->{html_url};
        # use Data::Dumper; warn Dumper($row);
    }
}


sub decode {
    my ($self, $data) = @_;

    my $enc = guess_encoding($data, qw/utf8 euc-jp sjis/);
    ref $enc or return $data;
    $enc->decode($data);

    return $data;
}

1;

