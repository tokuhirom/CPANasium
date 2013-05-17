requires 'perl', '5.12.0';
requires 'Amon2'                           => '3.80';
requires 'Text::Xslate'                    => '1.6001';
requires 'Teng',                            '0.18';
requires 'DBD::SQLite'                     => '1.33';
requires 'HTML::FillInForm::Lite'          => '1.11';
requires 'JSON'                            => '2.50';
requires 'Module::Functions'               => '2';
requires 'Plack::Middleware::ReverseProxy' => '0.09';
requires 'Plack::Middleware::Session'      => '0';
requires 'Plack::Session'                  => '0.14';
requires 'Test::WWW::Mechanize::PSGI'      => '0';
requires 'Time::Piece'                     => '1.20';
requires 'Pithub', 0;
requires 'Mouse';
requires 'Log::Minimal';
requires 'Furl';
requires 'LWP::UserAgent::Cached';

on 'configure' => sub {
   requires 'Module::Build'     => '0.38';
   requires 'Module::CPANfile' => '0.9010';
};

on 'test' => sub {
   requires 'Test::More'     => '0.98';
};
