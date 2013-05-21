package CPANasium::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;

    my %deps_ranking;
    for my $phase (qw/configure runtime test build develop/) {
        $deps_ranking{$phase} = [$c->db->search_by_sql(
            q{select module, count(*) as count from deps where phase=? group by module order by count(*) desc limit 30},
            [$phase],
        )];
    }
    my @authors = $c->db->search_by_sql(q{SELECT owner_login, count(*) count FROM repos GROUP BY owner_login ORDER BY count(*) DESC});
    my @recent_repos = $c->db->search_by_sql(q{select full_name, created_on from repos order by id desc limit 10;});
    return $c->render('index.tt', {
        deps_ranking => \%deps_ranking,
        authors      => \@authors,
        recent_repos => \@recent_repos,
    });
};

get '/module/:module' => sub {
    my ($c, $args) = @_;
    my $module = $args->{module};

    my @repos = $c->db->search_by_sql(
        q{SELECT distinct * FROM deps INNER JOIN repos ON (repos_full_name=repos.full_name) WHERE module=?},
        [$module],
    );

    return $c->render('module.tt', {
        module => $module,
        repos => \@repos,
    });
};

get '/user/:user' => sub {
    my ($c, $args) = @_;
    my $user = $args->{user};

    my @repos = $c->db->search_by_sql(
        q{SELECT * FROM repos WHERE owner_login=?},
        [$user],
    );

    my %deps_ranking;
    for my $phase (qw/configure runtime test/) {
        $deps_ranking{$phase} = [$c->db->search_by_sql(
            q{select module, count(*) as count from deps INNER JOIN repos ON (repos.full_name=deps.repos_full_name) where phase=? AND repos.owner_login=? group by module order by count(*) desc limit 30},
            [$phase, $user],
        )];
    }

    return $c->render('user.tt', {
        user => $user,
        deps_ranking => \%deps_ranking,
        repos => \@repos,
    });
};

get '/user/:user/:module' => sub {
    my ($c, $args) = @_;
    my $user = $args->{user};
    my $module = $args->{module};

    my ($repo) = $c->db->search_by_sql(
        q{SELECT * FROM repos WHERE full_name=?},
        [$user . '/' . $module],
    ) or die;
    my @deps = $c->db->search_by_sql(
        q{SELECT * FROM deps WHERE repos_full_name=? ORDER BY phase, relationship},
        [$user . '/' . $module],
    );
    return $c->render('repo.tt', {
        repo => $repo,
        deps => \@deps,
    });
};

1;
