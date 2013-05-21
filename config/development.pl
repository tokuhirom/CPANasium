use File::Spec;
use File::Basename qw(dirname);
use File::Path;
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
mkpath("/tmp/CPANasium-$<");

+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbpath", '', '',
        +{
            sqlite_unicode => 1,
            RaiseError => 1,
        }
    ],
    'LWP::UserAgent::WithCache' => {
        cache_root => "/tmp/CPANasium-$</"
    },
    'Pithub' => {
    },
    Github => {
        client_id => 'd06849c1d34c0e8855dc',
        client_secret => '41ca8c462507062ecc373f2e83ad41eba5007188',
    },
};
