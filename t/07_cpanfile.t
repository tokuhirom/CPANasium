use strict;
use warnings;
use utf8;
use Test::More;
use File::pushd;
use Module::CPANfile::Safe;
use File::Temp qw(tempdir);

subtest 'ok' => sub {
    my $guard = pushd(tempdir(CLEANUP => 1));
    spew(cpanfile => q!requires 'Data::Dumper';!);
    my $cpanfile = Module::CPANfile::Safe->load();
    my $prereqs = $cpanfile->prereq_specs();
    is($prereqs->{runtime}->{requires}->{'Data::Dumper'}, 0);
};

subtest 'fail' => sub {
    my $guard = pushd(tempdir(CLEANUP => 1));
    spew(cpanfile => q!
        open my $fh, '>', 'hoge';
        print $fh "FUGA";
        close $fh;
    !);
    my $cpanfile = Module::CPANfile::Safe->load('cpanfile');
    my $prereqs = $cpanfile->prereq_specs();
    is_deeply($prereqs, {});
    ok !-f 'hoge';
};

done_testing;

sub spew {
    my $fname = shift;
    open my $fh, '>', $fname
        or Carp::croak("Can't open '$fname' for writing: '$!'");
    print {$fh} $_[0];
}
