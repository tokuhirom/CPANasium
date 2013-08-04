package CPANasium::Model::Repo;

use strict;
use warnings;
use utf8;
use SQL::Maker;

use Mouse;

has json => ( is => 'ro' );
has db => ( is => 'ro' );
has ua => ( is => 'ro' );
has pithub => ( is => 'ro' );
has client_id => ( is => 'ro', isa => 'Str', required => 1 );
has client_secret => ( is => 'ro', isa => 'Str', required => 1 );
has pithub => (is => 'ro', required => 1);

no Mouse;
sub search {
    my ($self, %param) = @_;

    return (undef, undef) if (defined $param{keyword} && !$param{keyword});

    my $keyword = $param{keyword} || undef;
    my $filter = $param{filter} || 'all';


    my $sql_maker = SQL::Maker->new(driver => 'mysql');
    my $builder = $sql_maker->new_select;

    $builder->add_from('repos');
    $builder->add_select('*');

    my @search_fields = qw/data full_name description/;
    my $concat  = 'concat(' . join(',', @search_fields) . ')';
    $builder->add_select(\$concat => 'search_fields');

    my $where_keyword;
    if ($keyword) {
        my %condition = (
            'LIKE' => '%' . $keyword . '%',
        );
        $where_keyword = $builder->new_condition;
        $where_keyword->add(\$concat, \%condition);
    }

    $builder->set_where($where_keyword) if $where_keyword;

    my $sql = $builder->as_sql;
    my @binds = $builder->bind;
    my ($rows, $pager) = $self->db->search_by_sql_with_pager($sql, \@binds, {page => $param{page}||1, rows => 20});
    return ($rows, $pager);
}


1;
