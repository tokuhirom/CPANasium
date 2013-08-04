package CPANasium::DB;
use strict;
use warnings;
use utf8;

use parent qw(Teng);

__PACKAGE__->load_plugin('Replace');
__PACKAGE__->load_plugin('Pager');
__PACKAGE__->load_plugin('SearchBySQLWithPager');

1;

