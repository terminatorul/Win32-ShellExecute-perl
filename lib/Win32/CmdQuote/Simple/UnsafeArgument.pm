package Win32::CmdQuote::Simple::UnsafeArgument;

use strict;
use warnings;
use parent 'Exporter';
use overload '""' => 'message';
use English;
use Carp;

BEGIN
{
    our $VERSION = '1.0';
}

sub new
{
    my($package, $arg, $compound) = @ARG;

    return bless
    {
	arg => $arg, compound => $compound, message => Carp::shortmess("Failed to quote unsafe characters [$compound] in command argument [$arg]")
    }, $package
}

sub argument
{
    return (shift)->{'arg'}
}

sub compound
{
    return (shift)->{'compound'}
}

sub message
{
    return (shift)->{'message'}
}

return !undef
