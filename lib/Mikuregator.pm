package Mikuregator;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='0.02';
use 5.008001;


use DBI;
use Teng::Schema::Loader;
use LWP::UserAgent::WithCache;
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
        JSON::XS->new->ascii(1)->utf8(1);
    },
);

has db => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Teng::Schema::Loader->load(
            dbh       => $self->dbh,
            namespace => 'Mikuregator::DB'
        );
    },
);

has ua => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $c = shift;
        my $conf = $c->config->{'LWP::UserAgent::WithCache'} // die;
        LWP::UserAgent::WithCache->new(
            timeout => 6,
            namespace => 'lwp-cache',
            default_expires_in => 600,
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
            ua => $c->ua,
            auto_pagination => 1,
        );
    },
);

no Mouse;

use Module::Load;

sub batch {
    my ($self, $name) = @_;
    $self->load_component('Batch', $name);
}

sub model {
    my ($self, $name) = @_;
    $self->load_component('Model', $name);
}

sub load_component {
    my ($self, $base, $name) = @_;

    $self->{"$base#$name"} //= do {
        my $klass = $name =~ s/^\+// ? $name : "Mikuregator::${base}::$name";
        Module::Load::load($klass);
        my %params;
        for my $attr ($klass->meta->get_attribute_list) {
            if ($attr eq 'c') {
                $params{c} = $self;
            } else {
                $params{$attr} = $self->$attr;
            }
        }
        $klass->new(%params);
    };
}

sub client_id { shift->config->{Github}->{client_id} }
sub client_secret { shift->config->{Github}->{client_secret} }

1;
