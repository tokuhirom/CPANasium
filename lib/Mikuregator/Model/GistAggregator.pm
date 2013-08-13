package Mikuregator::Model::GistAggregator;
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

my $URL = 'https://gist.github.com/search?q=mikutter+OR+%22%E3%81%BF%E3%81%8F%E3%81%A3%E3%81%9F%22'; # mikutter OR "みくった"
#my $URL = 'https://gist.github.com/search?l=ruby&q=%22Plugin.create%22'; # "Plugin.create"

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
sub get_gist_list {
    my ($self, $page) = @_;
    my $wq = wq($URL . ($page ? "&page=$page" : ''))->find('.gist-item a .css-truncate-target')->map(sub {
        my ($i, $elem) = @_;
        my $href = $elem->parent->attr('href');#text;
        $href;
    });
    return @$wq;
}

# @args $repo: 'miyagawa/CGI-Compile'
sub get_gist_info {
    my ($self, $repo) = @_;

    my ($gist_id) = $repo =~ m! .+/(.*?)$ !x;

    my $res = $self->pithub->gists->get(
        gist_id => $gist_id
    );
    return $res;
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
            next unless $_data;
            $repo_class = "plugin" if ($_data =~ m/(plugin)|(プラグイン)|(ﾌﾟﾗｸﾞｲﾝ)/i);
        }

        my $params = +{
            master_branch => 'master',
            host_type     => 'gist',
            repo_class    => $repo_class,
            html_url      => $row->{html_url},
            name          => $row->{id},
            full_name     => $row->{user}->{login} . '/' . $row->{id},
            owner_avatar_url => $row->{user}->{avatar_url},
            'description' => $self->decode($row->{description}),
            forks         => '', #$row->{forks},
            watchers      => $row->{watchers} || '',
            owner_login   => $row->{user}->{login},
            updated_at    => $self->parse_time($row->{updated_at})->epoch,
            created_at    => $self->parse_time($row->{created_at})->epoch,
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

