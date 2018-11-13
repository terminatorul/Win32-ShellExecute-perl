
package Win32::CmdQuote::Simple;

use strict;
use warnings;
use parent 'Exporter';
use English;
use Win32::CmdQuote::Simple::UnsafeArgument;

BEGIN
{
    our $VERSION = '1.0';
    our @EXPORT_OK = ('$QUOTE_ARGS', '&quote_args', 'CMD_METACHARACTERS');
}

use constant { false => !!undef, true => !undef };
use constant CMD_METACHARACTERS => ' ]& |<>[)({}^=;\'+,`~' . "\e\t\x0B\f\r\n\0";	# Output from `cmd /?`
our $QUOTE_ARGS = true;

sub quote_args
{
    if ($QUOTE_ARGS)
    {
	for (@ARG)
	{
	    my $compound = '';

	    $compound .= '"' if $ARG =~ m/"/;
	    $compound .= '%' if $ARG =~ m/%/;

	    die Win32::CmdQuote::Simple::UnsafeArgument->new($ARG, $compound) if $compound
	}

	return map { if ($ARG =~ m/[\Q${\CMD_METACHARACTERS}\E]/) { '"' . ($ARG =~ s/(\\*)$/"$1/r) } else { $ARG } } @ARG
    }

    return @ARG
}

return true
