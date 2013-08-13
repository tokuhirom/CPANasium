use File::Spec;
use File::Basename qw(dirname);
use File::Path;
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
mkpath("/tmp/Mikuregator-$<");

+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbpath", '', '',
        +{
            sqlite_unicode => 1,
            RaiseError => 1,
        }
    ],
    'LWP::UserAgent::WithCache' => {
        cache_root => "/tmp/Mikuregator-$</"
    },
    'Pithub' => {
    },
    Github => {
        client_id => 'CLIENT_ID',
        client_secret => 'CLIENT_SECRET',
    },
};
