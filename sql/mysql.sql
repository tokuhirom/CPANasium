CREATE TABLE repos (
    id integer not null primary key auto_increment,
    host_type varchar(255), -- "gist" or "github"
    repo_class varchar(255), -- "plugin" or ""
    name varchar(255),
    owner_login varchar(255),
    full_name varchar(255),
    master_branch varchar(255),
    repo_url text,
    html_url text,
    owner_avatar_url varchar(255),
    description varchar(255),
    watchers integer,
    forks    integer,
    data      text,
    cpanfile  text,
    updated_at integer,
    created_at integer,
    index (owner_login),
    unique (full_name),
    index (updated_at)
) ENGINE=InnoDB charset=utf8;

create table deps (
    repos_full_name varchar(255) not null,
    -- configure,develop,test,runtime,build
    phase varchar(255) not null,
    -- requires, recommends, suggests
    relationship varchar(255) not null,
    module varchar(255) not null,
    version varchar(255) not null,
    created_on integer,
    index (module),
    index (repos_full_name),
    unique (repos_full_name, phase, relationship, module)
) ENGINE=InnoDB charset=utf8;

