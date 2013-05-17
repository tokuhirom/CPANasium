package CPANasium::Aggregator;
use strict;
use warnings;
use utf8;
use Pithub;
use Log::Minimal;
use Furl;
use LWP::UserAgent::Cached;
use Module::CPANfile;
use File::Temp;

use Mouse;

has json => ( is => 'ro' );
has db => ( is => 'ro' );
has ua => ( is => 'ro' );
has pithub => ( is => 'ro' );
has client_id => ( is => 'ro', isa => 'Str', required => 1 );
has client_secret => ( is => 'ro', isa => 'Str', required => 1 );

no Mouse;

sub aggregate {
    my ($self, $type, $github_id) = @_;
    $github_id // die;

    my $result = $self->pithub->request(
        method => 'GET',
        path   => sprintf( "/%s/%s/repos", $type eq 'user' ? 'users' : 'orgs', $github_id ),
        params => {
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            type          => 'public',
            per_page      => 100000,
        },
    );
    $result->auto_pagination(1);

    print $result->response->headers->as_string;

    unless ( $result->success ) {
        printf "something is fishy:\n";
        print $result->response->request->as_string;
        print "\n--\n";
        print $result->response->as_string;
        print "\n--\n";
        exit 1;
    }
    while ( my $row = $result->next ) {
        next if $row->{private};
        next if $row->{fork};

        use Data::Dumper; warn Dumper($row);
        my $params = +{
            master_branch => $row->{master_branch},
            html_url      => $row->{html_url},
            name          => $row->{name},
            full_name     => $row->{full_name},
            owner_avatar_url => $row->{owner}->{avatar_url},
            'description' => $row->{description},
            forks         => $row->{forks},
            owner_login   => $row->{owner}->{login},
            created_on    => time,
        };
        my $cpanfile = sprintf 'https://raw.github.com/%s/master/cpanfile', $row->{full_name}, $row->{master_branch};
        infof("Fetching cpanfile from %s", $cpanfile);
        my $res = $self->ua->get($cpanfile);
        if ($res->is_success) {
            my $cpanfile = $res->content;
            $self->db->replace(
                repos => {
                    %$params,
                    data     => $self->json->encode($row),
                    cpanfile => $cpanfile,
                }
            );
            infof('%s', ddf($params));
        }
        ## $row->{watchers};
        ## $row->{master_branch};
        ## $row->{html_url};
        # use Data::Dumper; warn Dumper($row);
    }
}


1;
__END__

=head1 SYNOPSIS

    my $cpan = CPANasium::Aggregator->new();
    $cpan->aggregate('user', 'tokuhirom');
    $cpan->aggregate('org', 'CPAN-API');

