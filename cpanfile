requires 'perl', '5.12.0';

requires 'Amon2'                           => '3.80';
requires 'Amon2::Web';
requires 'Amon2::Web::Dispatcher::Lite';
requires 'autodie';
requires 'DBD::SQLite'                     => '1.33';
requires 'DBI';
requires 'File::Temp';
requires 'Furl';
requires 'HTML::FillInForm::Lite'          => '1.11';
requires 'JSON'                            => '2.50';
requires 'JSON::PP';
requires 'JSON::XS';
requires 'Log::Minimal';
requires 'LWP::UserAgent::Cached';
requires 'LWP::UserAgent::WithCache';
requires 'Module::CPANfile';
requires 'Module::Functions'               => '2';
requires 'Module::Load';
requires 'Moo';
requires 'Mouse';
requires 'parent';
requires 'Pithub', 0;
requires 'Plack::Builder';
requires 'Plack::Middleware::ReverseProxy' => '0.09';
requires 'Plack::Middleware::Session'      => '0';
requires 'Plack::Session'                  => '0.14';
requires 'Plack::Session::State::Cookie';
requires 'Plack::Session::Store::DBI';
requires 'Pod::Usage';
requires 'Teng',                            '0.18';
requires 'Teng::Schema::Loader';
requires 'Test::WWW::Mechanize::PSGI'      => '0';
requires 'Text::Xslate'                    => '1.6001';
requires 'Time::Piece'                     => '1.20';
requires 'Web::Query';

on 'configure' => sub {
   requires 'Module::Build'     => '0.38';
   requires 'Module::CPANfile' => '0.9010';
};

on 'test' => sub {
   requires 'Test::More'     => '0.98';
    requires 'File::pushd';
    requires 'Plack::Test';
    requires 'Plack::Util';
    requires 'Test::Requires';
};

