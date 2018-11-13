
package Win32::CmdQuote::Simple;

use strict;
use warnings;
use parent 'Exporter';
use English;
use Carp;

BEGIN
{
    our $VERSION = '1.0';
    our @EXPORT_OK = ('$QUOTE_ARGS', '&quote_args', 'CMD_METACHARACTERS');
}

use constant { false => !!undef, true => !undef };
use constant CMD_METACHARACTERS => ' ]& |<>[)({}^=;\'+,`~';	# Output from `cmd /?`
our $QUOTE_ARGS = true;

sub quote_args
{
    if ($QUOTE_ARGS)
    {
	for (@ARG)
	{
	    Carp::croak "Failed to quote unsafe command argument: $ARG" if $ARG =~ m/"/
	}

	return map { if ($ARG =~ m/[\Q${\CMD_METACHARACTERS}\E]/) { '"' . ($ARG =~ s/(\\*)$/"$1/r) } else { $ARG } } @ARG
    }

    return @ARG
}

return true
