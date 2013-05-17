package Module::CPANfile::Safe;
use strict;
use warnings;
use utf8;
use Child;
use Module::CPANfile;
use File::Temp;

# XXX It's not safe.
# TODO: make it safety.

sub load_from_string {
    my ($class, $src) = @_;
    my $tmp = File::Temp->new();
    warn $src;
    print {$tmp} $src;
    close $tmp;

    my $cpanfile = Module::CPANfile->load($tmp->filename);
    unlink $tmp;
    return bless {
        _cpanfile =>$cpanfile,
    }, $class;
}

sub prereq_specs {
    my ($self) = @_;
    $self->{_cpanfile}->prereq_specs;
}

1;

