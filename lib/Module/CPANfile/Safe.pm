package Module::CPANfile::Safe;
use strict;
use warnings;
use utf8;
use parent qw(Module::CPANfile);
use Module::CPANfile;
use File::Temp;
use Safe;
use Module::Functions qw(get_public_functions);
use JSON::PP qw(decode_json);
use File::Temp;

my $FILE_ID = 0;

sub parse {
    my $self = shift;

    my $file = Cwd::abs_path($self->{file});

    my $tmpfile = File::Temp->new();

    package main; # seems necessary

    my $pid = fork();
    die "Can't fork: $!" unless defined $pid;

    my $result;
    if ($pid) {
        waitpid($pid, 0);
        if (open my $fh, '<:raw', $tmpfile) {
            my $json= do { local $/; <$fh> };
            $result = Module::CPANfile::Result->from_prereqs(JSON::PP::decode_json($json));
        }
    } else {
        # memory limit is required.

        my $safe = Safe->new();
        for my $func (Module::Functions::get_public_functions('Module::CPANfile::Result')) {
            $safe->share("*Module::CPANfile::Result::${func}");
        }
        $safe->share("*Module::CPANfile::Environment::import");

        my $code = do {
            open my $fh, "<", $file or die "$file: $!";
            join '', <$fh>;
        };

        my $cpanfile_result = $safe->reval(sprintf(<<'...', $FILE_ID++, $file, $code));
package Module::CPANfile::Sandbox%d;
my $result;
BEGIN { Module::CPANfile::Environment->import( \$result ); }

# line 1 "%s"
%s

$result;
...

        open my $fh, '>', $tmpfile->filename
            or die;
        print {$fh} JSON::PP->new->ascii(1)->encode(ref($cpanfile_result) ? $cpanfile_result->{spec} : {});
        close $fh;
        exit 0;
    }
    unlink $tmpfile if -f $tmpfile;

    $self->{result} = $result or die $@;
}

1;
