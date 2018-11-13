use warnings;
use strict;
use English;
use Test::More tests => 2;
use FindBin;
use File::Spec::Unix;
use lib File::Spec::Unix->catdir($FindBin::Bin, File::Spec::Unix->updir(), 'lib');
use Win32::ShellExecute;


my $subprocess_id = Win32::ShellExecute::shell_execute($ENV{'COMSPEC'}, qw(/C Exit 0));
waitpid $subprocess_id, 0 if $subprocess_id;

ok($subprocess_id && !$CHILD_ERROR, 'shell execute');

# $Win32::ShellExecute::VERB = 'properties';
my $shellCommand = Win32::ShellExecute->new($ENV{'COMSPEC'}, qw(/C Exit 8));
$subprocess_id = $shellCommand->run();

waitpid $subprocess_id, 0 if $subprocess_id;

ok(defined($subprocess_id) && (!$subprocess_id || $CHILD_ERROR == 8 << 8), 'shell execute');

my $wnd = Win32::ShellExecute->find_process_window(undef);
say STDERR "Found window $wnd, console window ", Win32::ShellExecute::GetConsoleWindow()
