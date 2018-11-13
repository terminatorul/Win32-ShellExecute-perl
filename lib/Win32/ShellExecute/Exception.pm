package Win32::ShellExecute::Exception;

use warnings;
use strict;
use parent 'Exporter';
use overload '""' => 'message';
use English;

use constant
{
    ERR_FNF => 2, ERR_PNF => 3, ERR_ACCESSDENIED => 5, ERR_OOM => 8, ERR_DLLNOTFOUND => 32, ERR_SHARE => 26,
    ERR_ASSOCINCOMPLETE => 27, ERR_DDETIMEOUT => 28, ERR_DDEFAIL => 29, ERR_DDEBUSY => 30, ERR_NOASSOC => 31
};

BEGIN
{
    our $VERSION = '1.0';
    our @EXPORT_OK = (qw(ERR_FNF ERR_PNF ERR_ACCESSDENIED ERR_OOM ERR_DLLNOTFOUND ERR_SHARE ERR_ASSOCINCOMPLETE
	    ERR_DDETIMEOUT ERR_DDEFAIL ERR_DDEBUSY ERR_NOASSOC), 'shellexecute_error_message');

    our @EXPORT_TAGS = (':err' => [qw(ERR_FNF ERR_PNF ERR_ACCESSDENIED ERR_OOM ERR_DLLNOTFOUND ERR_SHARE ERR_ASSOCINCOMPLETE
	    ERR_DDETIMEOUT ERR_DDEFAIL ERR_DDEBUSY ERR_NOASSOC)]);
}

sub shellexecute_error_message
{
    for ($ARG[0])
    {
	return 'File not found.' if $ARG eq ERR_FNF;
	return 'Path not found.' if $ARG eq ERR_PNF;
	return 'Access denied.' if $ARG eq ERR_ACCESSDENIED;
	return 'Out of memory.' if $ARG eq ERR_OOM;
	return 'Dynamic-link library not found.' if $ARG eq ERR_DLLNOTFOUND;
	return 'Cannot share an open file.' if $ARG eq ERR_SHARE;
	return 'File association information not complete.' if $ARG eq ERR_ASSOCINCOMPLETE;
	return 'DDE operation timed out.' if $ARG eq ERR_DDETIMEOUT;
	return 'DDE operation failed.' if $ARG eq ERR_DDEFAIL;
	return 'DDE operation is busy.' if $ARG eq ERR_DDEBUSY;
	return 'File association not available.' if $ARG eq ERR_NOASSOC;
    }

    return 'Execute shell command failed';
}

sub new
{
    my($package, $code) = (shift, shift);

    my %exception = ( 'code' => $code, 'message' => shellexecute_error_message($code) );

    return bless \%exception, $package
}

sub code
{
    return (shift)->{'code'}
}

sub message
{
    return (shift)->{'message'}
}

return !undef
