package Win32::SystemError;

use strict;
use warnings;
use parent 'Exporter';
use overload '""' => 'message';
use English;
use Carp ();
use Win32;

BEGIN
{
    our $VERSION = '0.8';
}

sub new
{
    my($package, $code, @args) = @ARG;

    bless { 'code' => $code, 'message' => Carp::shortmess(Win32::FormatMessage($code)), 'args' => [ @args ] }, $package
}

sub code
{
    return (shift)->{'code'}
}

sub message
{
    return (shift)->{'message'}
}

sub args
{
    return @{(shift)->{'args'}}
}

return !undef
