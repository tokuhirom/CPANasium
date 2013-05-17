package CPANasium;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;


use CPANasium::Aggregator;
use DBI;
use Teng::Schema::Loader;
use LWP::UserAgent::Cached;
use Pithub;
use JSON::XS;

use Mouse;

has dbh => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->config->{DBI} // die "Missing configuration for DBH";
        DBI->connect(@$conf);
    },
);

has json => (
    is => 'ro',
    lazy => 1,
    default => sub {
        JSON::XS->new->ascii(1);
    },
);

has db => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Teng::Schema::Loader->load(
            dbh       => $self->dbh,
            namespace => 'CPANasium::DB'
        );
    },
);

has ua_cached => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $c = shift;
        my $conf = $c->config->{'LWP::UserAgent::Cached'} // die;
        LWP::UserAgent::Cached->new(
            timeout => 6,
            %$conf
        );
    }
);

has pithub => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $c = shift;
        my $conf = $c->config->{'Pithub'} // die;
        Pithub->new(
            %$conf,
            ua => $c->ua_cached,
            auto_pagination => 1,
        );
    },
);

has aggregator => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->config->{'CPANasium::Aggregator'} // die;
        CPANasium::Aggregator->new(
            %$conf,
            db => $self->db,
            ua => $self->ua_cached,
            json => $self->json,
            pithub => $self->pithub,
        )
    },
);

no Mouse;

use Module::Load;

sub batch {
    my ($self, $name) = @_;
    Module::Load::load("CPANasium::Batch::$name");
    "CPANasium::Batch::$name"->new(db => $self->db);
}

1;
