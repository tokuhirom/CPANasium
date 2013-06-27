package CPANasium::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;

    my @count_repos = $c->db->search_by_sql(q{select host_type, count(host_type) as `count` from repos group by host_type});
    my @count_authors = $c->db->search_by_sql(q{select distinct(owner_login) from repos});
    my @authors = $c->db->search_by_sql(q{SELECT host_type, owner_login, owner_avatar_url, count(*) as `count` FROM repos GROUP BY owner_login ORDER BY count(*) DESC LIMIT 10});
    my @recent_repos = $c->db->search_by_sql(q{select host_type, owner_login, owner_avatar_url, full_name, html_url, description, created_at, updated_at from repos order by updated_at desc limit 10;});

    return $c->render('index.tt', {
        authors      => \@authors,
        recent_repos => \@recent_repos,
        count_repos  => \@count_repos,
        count_authors  => scalar @count_authors,
    });
};

get '/about' => sub {
    my ($c) = @_;
    return $c->render('about.tt');
};

get '/authors' => sub {
    my ($c) = @_;
    my $page = $c->req->param('page') || 1;
    my ($authors, $pager) = $c->db->search_with_pager(
        'repos' => {},
            {group_by => 'owner_login', order_by => 'count(*) desc', page => $page, rows => 30,
            columns => [\'count(*) as count', 'owner_login', 'owner_avatar_url']});
    return $c->render('authors.tt', {
        authors => $authors,
        pager   => $pager,
    });
};


get '/recent' => sub {
    my ($c) = @_;

    my $page = $c->req->param('page') || 1;
    my ($recent_repos, $pager) = $c->db->search_with_pager('repos' => {}, {order_by => 'updated_at desc', page => $page, rows => 50});
    return $c->render('recent.tt', {
        recent_repos => $recent_repos,
        pager => $pager,
    });
};

get '/user/:user' => sub {
    my ($c, $args) = @_;
    my $user = $args->{user};

    my @repos = $c->db->search_by_sql(
        q{SELECT * FROM repos WHERE owner_login=? order by updated_at desc},
        [$user],
    );

    return $c->render('user.tt', {
        user => $user,
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
    return $c->render('repo.tt', {
        repo => $repo,
    });
};


any '/random' => sub {
    my ($c) = @_;

    my @repos = $c->db->search_by_sql(q{select * from repos order by rand() limit 10});

    return $c->render('random.tt', {
        repos => \@repos,
    });
};


1;
