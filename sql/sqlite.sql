CREATE TABLE repos (
    id integer not null primary key,
    name varchar(255),
    owner_login varchar(255),
    full_name varchar(255),
    master_branch varchar(255),
    html_url text,
    owner_avatar_url varchar(255),
    description varchar(255),
    watchers integer,
    forks    integer,
    data      text,
    cpanfile  text,
    updated_at integer,
    created_at integer
);
create index repos_owner_login on repos (owner_login);
create unique index repos_full_name on repos (full_name);
create index repos_updated_at on repos (updated_at);


create table deps (
    repos_full_name varchar(255) not null,
    -- configure,develop,test,runtime,build
    phase varchar(255) not null,
    -- requires, recommends, suggests
    relationship varchar(255) not null,
    module varchar(255) not null,
    version varchar(255) not null,
    created_on integer
);
create index deps_module on deps (module);
create index deps_repos_full_name on deps (repos_full_name);
create unique index deps_repos_full_name_phase_relationship_module on deps (repos_full_name, phase, relationship, module);
