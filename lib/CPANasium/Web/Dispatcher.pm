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
    my @count_repos = $c->db->search_by_sql(q{select host_type, count(host_type) as `count` from repos group by host_type});
    my @authors = $c->db->search_by_sql(q{SELECT owner_login, count(*) count FROM repos GROUP BY owner_login ORDER BY count(*) DESC});
    my @recent_repos = $c->db->search_by_sql(q{select full_name, html_url, description, created_at, updated_at from repos order by updated_at desc limit 20;});
    return $c->render('index.tt', {
        deps_ranking => \%deps_ranking,
        authors      => \@authors,
        recent_repos => \@recent_repos,
        count_repos  => \@count_repos,
    });
};

get '/categories' => sub {
    my $c = shift;

    my @categories = (
        {
            title => 'Web Application Frameworks',
            modules => [
                'Mojolicious',
                'Amon2',
                'Catalyst',
                'Web::Simple',
            ],
        },
        {
            title => 'OO',
            modules => [
                'Class::Accessor::Fast',
                'Class::Accessor::Lite',
                'Moose',
                'Mouse',
                'Moo',
            ],
        },
    );
    for my $category (@categories) {
        my @modules = @{$category->{modules}};
        my @summary = $c->db->search_by_sql(
            q{SELECT module, count(*) as count FROM deps WHERE module IN (} . join(',', ('?')x@modules) . ') GROUP BY module order by count desc',
            [@modules],
        );
        $category->{summary} = \@summary;
    }
    $c->render(
        'categories.tt' => {
            categories => \@categories,
        }
    );
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
        q{SELECT * FROM repos WHERE owner_login=? order by updated_at desc},
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
