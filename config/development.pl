use File::Spec;
use File::Basename qw(dirname);
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
#my $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
+{
    'DBI' => [
        #"dbi:SQLite:dbname=$dbpath", '', '',
        #+{
        #    sqlite_unicode => 1,
        #}
        "dbi:mysql:dbname=mikuregator", 'root', '',
        +{
            mysql_enable_utf8 => 1,
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
    'Text::Xslate' => {
        # TODO: Kolon にする
        syntax => 'TTerse',
    },
};

