package Win32::ShellExecute::SystemError;

use warnings;
use strict;
use parent 'Exporter', 'Win32::SystemError';

sub verb
{
    return ((shift)->args())[0]
}

sub file
{
    return ((shift)->args())[1]
}

sub parameters
{
    return ((shift)->args())[2]
}

sub command
{
    my $err = shift;
    my($file, $params) = ($err->file, $err->params);
    return join ' ', $file, $params
}

return !undef
