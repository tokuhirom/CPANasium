package Mikuregator::DB::Schema;
use strict;
use warnings;
use utf8;

use Teng::Schema::Declare;

base_row_class 'Mikuregator::DB::Row';

table {
    name 'repos';
    pk 'id';
    columns qw(
        id
        host_type
        repo_class
        name
        owner_login
        full_name
        master_branch
        repo_url
        html_url
        owner_avatar_url
        description
        watchers
        forks
        data
        cpanfile
        updated_at
        created_at
    );
};

1;
