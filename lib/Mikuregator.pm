package Mikuregator;
use strict;
use warnings;
use utf8;
our $VERSION='0.01';
use 5.008001;
use Mikuregator::DB::Schema;
use Mikuregator::DB;
use Pithub;
use JSON;
use LWP::UserAgent::WithCache;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

my $schema = Mikuregator::DB::Schema->instance;

sub db {
    my $c = shift;
    if (!exists $c->{db}) {
        my $conf = $c->config->{DBI}
            or die "Missing configuration about DBI";
        $c->{db} = Mikuregator::DB->new(
            schema       => $schema,
            connect_info => [@$conf],
            # I suggest to enable following lines if you are using mysql.
            # on_connect_do => [
            #     'SET SESSION sql_mode=STRICT_TRANS_TABLES;',
            # ],
        );
    }
    $c->{db};
}

sub json {
    my $c = shift;
    $c->{json} //= JSON->new->ascii(1)->utf8(1);
}

sub ua {
    my $c = shift;
    my $conf = $c->config->{'LWP::UserAgent::WithCache'} // die;
    $c->{ua} //= LWP::UserAgent::WithCache->new(
        timeout => 6,
        namespace => 'lwp_cache',
        default_expires_in => 600,
        %$conf,
    );
}

sub pithub {
    my $c = shift;
    my $conf = $c->config->{'Pithub'};
    $c->{pithub} //= Pithub->new(
        ua => $c->ua,
        auto_pagination => 1,
        %$conf,
    );
}

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
__END__

=head1 NAME

Mikuregator - Mikuregator

=head1 DESCRIPTION

This is a main context class for Mikuregator

=head1 AUTHOR

Mikuregator authors.

