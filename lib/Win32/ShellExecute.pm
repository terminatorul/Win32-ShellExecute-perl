
package Win32::ShellExecute;

use strict;
use warnings;
use feature 'say';
use overload '&{}' => 'execute';
use English;
use Carp;
use Win32::CmdQuote::Simple;
use Win32::ShellExecute::Exception;

use constant { false => !!undef, true => !undef };
use constant
{
    SEE_MASK_DEFAULT => 0x00000000, SEE_MASK_CLASSNAME => 0x00000001, SEE_MASK_CLASSKEY => 0x00000003, SEE_MASK_IDLIST => 0x00000004,
    SEE_MASK_INVOKEIDLIST => 0x0000000C, SEE_MASK_ICON => 0x00000010, SEE_MASK_HOTKEY => 0x00000020, SEE_MASK_NOCLOSEPROCESS => 0x00000040,
    SEE_MASK_CONNECTNETDRV => 0x00000080, SEE_MASK_NOASYNC => 0x00000100, SEE_MASK_FLAG_DDEWAIT => 0x00000100,
    SEE_MASK_FLAG_DOENVSUBST => 0x00000200, SEE_MASK_FLAG_NO_UI => 0x00000400, SEE_MASK_UNICODE => 0x00004000,
    SEE_MASK_NO_CONSOLE => 0x00008000, SEE_MASK_ASYNCOK => 0x00100000, SEE_MASK_NOQUERYCLASSSTORE => 0x01000000, 
    SEE_MASK_HMONITOR => 0x00200000, SEE_MASK_NO_ZONECHECKS => 0x00800000, SEE_MASK_WAITFORINPUTIDLE => 0x02000000,
    SEE_MASK_FLAG_LOG_USAGE => 0x04000000, SEE_MASK_FLAG_HINST_IS_SITE => 0x08000000
};

use constant
{
    SW_HIDE => 0, SW_MAXIMIZE => 3, SW_MINIMIZE => 6, SW_RESTORE => 9, SW_SHOW => 5, SW_SHOWDEFAULT => 10, SW_SHOWMAXIMIZED => 3,
    SW_SHOWMINIMIZED => 2, SW_SHOWMINNOACTIVE => 7, SW_SHOWNA => 8, SW_SHOWNOACTIVATE => 4, SW_SHOWNORMAL => 1
};

use constant
{
    COINIT_APARTMENTTHREADED => 0x02, COINIT_MULTITHREADED => 0x00, COINIT_DISABLE_OLE1DDE => 0x04, COINIT_SPPED_OVER_MEMORY => 0x08 
};

use constant { S_OK => 0, S_FALSE => 1 };

use parent 'Exporter';

BEGIN
{ 
    our @VERSION = '1.0';
    our @EXPORT_OK =
    (
	'shell_execute' 
    );
    our @EXPORT_TAGS =
    (
	':MASK' => qw(SEE_MASK_DEFAULT SEE_MASK_CLASSNAME SEE_MASK_CLASSKEY SEE_MASK_IDLIST
	    SEE_MASK_INVOKEIDLIST SEE_MASK_ICON SEE_MASK_HOTKEY SEE_MASK_NOCLOSEPROCESS SEE_MASK_CONNECTNETDRV SEE_MASK_NOASYNC
	    SEE_MASK_FLAG_DDEWAIT SEE_MASK_FLAG_DOENVSUBST SEE_MASK_FLAG_NOUI SEE_MASK_UNICODE SEE_MASK_NO_CONSOLE SEE_MASK_ASYNCOK
	    SEE_MASK_NOQUERYCLASSSTORE SEE_MASK_HMONITOR SEE_MASK_NO_ZONECHECKS SEE_MASK_WAITFORINPUTIDLE SEE_MASK_FLAG_LOG_USAGE
	    SEE_MASK_FLAG_HINST_IS_SITE),
	':SW' => qw(SW_HIDE SW_MAXIMIZE SW_MINIMIZE SW_RESTORE SW_SHOW SW_SHOWDEFAULT SW_SHOWMAXIMIZED SW_SHOWMINIMIZED
	    SW_SHOWMINNOACTIVE SW_SHOWNA SW_SHOWNOACTIVATE SW_SHOWNORMAL),
	':COINIT' => qw(COINIT_APARTMENTTHREADED COINIT_MULTITHREADED COINIT_DISABLE_OLE1DDE COINIT_SPPED_OVER_MEMORY S_OK S_FALSE),
	':API' => qw(CoInitializeEx CoUninitialize GetLastError SetLastError FindWindowExA GetWindowThreadProcessId
	    GetCurrentProcessId GetProcessId GetConsoleWindow ShellExecuteExA CloseHandle)
    )
}

use Win32::API ();

sub default_flags;

our $QUOTE_ARGS = true;
our $ProcessID;
our $APARTMENT = COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE;
our $FLAGS = &default_flags();
our $HWND = undef;
our $SHOW = SW_SHOWNORMAL;
our $DIRECTORY = undef;
our $VERB = undef;
our $CLASS = undef;
our $HOTKEY = 0;

Win32::API::Struct->typedef
    (
	SHELLEXECUTEINFOA =>
	    qw{
		DWORD      cbSize;
		ULONG      fMask;
		HWND       hWnd;
		LPCSTR     lpVerb;
		LPCSTR     lpFile;
		LPCSTR     lpParameters;
		LPCSTR     lpDirectory;
		int	   nShow;
		HINSTANCE  hInstApp;
		LPVOID     lpIDList;
		LPCSTR     lpClass;
		HKEY       hKeyClass;
		DWORD      dwHotKey;
		HANDLE     hMonitorOrIcon;
		HANDLE     hProcess;
	    }
    );

Win32::API::More->Import('Kernel32', 'DWORD GetLastError()');
Win32::API::More->Import('Kernel32', 'void SetLastError()');
Win32::API::More->Import('Kernel32', 'HWND GetConsoleWindow()');
Win32::API::More->Import('Kernel32', 'DWORD GetCurrentProcessId()');
Win32::API::More->Import('Kernel32', 'BOOL CloseHandle(HANDLE hObject)');
Win32::API::More->Import('Kernel32', 'DWORD GetProcessId(HANDLE hProcess)');
Win32::API::More->Import('User32',   'HWND FindWindowExA(HWND hWndParent, HWND hWndChildAfter, LPCSTR lpszClass, LPCSTR lpszWindow)');
Win32::API::More->Import('User32',   'DWORD GetWindowThreadProcessId(HWND hWnd, LPDWORD lpdwProcessId)');
Win32::API::More->Import('Shell32',  'BOOL ShellExecuteExA(SHELLEXECUTEINFOA *pExecInfo)');
Win32::API::More->Import('Ole32',    'LRESULT CoInitialize(LPVOID pvReserverd, DWORD dwCoInit)');
Win32::API::More->Import('Ole32',    'void CoUninitialize()');

sub co_initialize
{
    if (defined $APARTMENT && !ref $APARTMENT)
    {
	my $hResult = CoInitializeEx(0, $APARTMENT);
	
	if ($hResult == S_OK || $hResult == S_FALSE)
	{
	    $APARTMENT = [ ]
	}
    }
}

sub co_uninitialize
{
    if (ref $APARTMENT)
    {
	CoUninitialize();
	$APARTMENT = COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE
    }
}

END
{
    co_uninitialize
}

sub new
{
    my $package = shift;
    my $shellExecuteInfo = Win32::API::Struct->new('SHELLEXECUTEINFOA');

    $shellExecuteInfo->{cbSize} = $shellExecuteInfo->sizeof;
    $shellExecuteInfo->{fMask} = $FLAGS;

    if (defined $HWND)
    {
	$shellExecuteInfo->{hWnd} = $HWND
    }
    else
    {
	$shellExecuteInfo->{hWnd} = GetConsoleWindow();
	$shellExecuteInfo->{hWnd} = $package->find_process_window unless $shellExecuteInfo->{hWnd}
    }

    $shellExecuteInfo->{lpVerb} = $VERB;
    $shellExecuteInfo->{lpFile} = shift;
    Carp::croak 'Command or document name expected for call ShellExecute->command()' unless $shellExecuteInfo->{lpFile};

    {
	local $Win32::CmdQuote::Simple::QUOTE_ARGS = $QUOTE_ARGS;

	$shellExecuteInfo->{lpParameters} = ((join ' ', Win32::CmdQuote::Simple::quote_args @ARG) =~ s/"/"/gr);
    }

    $shellExecuteInfo->{lpDirectory} = $DIRECTORY; 
    $shellExecuteInfo->{nShow} = $SHOW;
    $shellExecuteInfo->{hInstApp} = 0;
    $shellExecuteInfo->{lpIDList} = 0;
    $shellExecuteInfo->{lpClass} = $CLASS;
    $shellExecuteInfo->{dwHotKey} = $HOTKEY;
    $shellExecuteInfo->{hKeyClass} = 0;
    $shellExecuteInfo->{hMonitorOrIcon} = 0;
    $shellExecuteInfo->{hProcess} = 0;

    return bless { shell_execute_info => $shellExecuteInfo }, $package
}

sub default_flags
{
    return
	SEE_MASK_DEFAULT | SEE_MASK_NOCLOSEPROCESS | SEE_MASK_CONNECTNETDRV |
	SEE_MASK_NOASYNC | SEE_MASK_NO_CONSOLE | SEE_MASK_FLAG_NO_UI
}

sub set_flags
{
    my($shellCommand, $flags) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{'fMask'} |= $flags
}

sub reset_flasgs
{
    my($shellExecuteInfo, $flags) = ((shift)->{'shell_execute_info'}, shift);

    if (defined $flags)
    {
	$shellExecuteInfo->{'fMask'} &= ~$flags
    }
    else
    {
	$shellExecuteInfo->{'fMask'} = SEE_MASK_DEFAULT
    }
}

sub wnd($)
{
    my($shellCommand, $wnd) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{hWnd} = $wnd
}

sub verb($)
{
    my($shellCommand, $verb) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{lpVerb} = $verb
}

sub file($)
{
    my($shellCommand, $file) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{lpFile} = $file
}

sub parameters
{
    my $shellCommand = shift;
    local $Win32::CmdQuote::Simple::QUOTE_ARGS = $QUOTE_ARGS;

    $shellCommand->{'shell_execute_info'}->{lpParameters} = join ' ', Win32::CmdQuote::Simple::quote_args @ARG
}

sub wnd_show($)
{
    my($shellCommand, $wnd_show) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{'nShow'} = $wnd_show
}

sub monitor($)
{
    my($shellCommand, $monitor) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'hMonitorOrIcon'} = $monitor;
    $shellExecInfo->{'fMask'} |= SEE_MASK_HMONITOR;
    $shellExecInfo->{'fMask'} &= ~SEE_MASK_ICON
}

sub icon($)
{
    my($shellCommand, $icon) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'hMonitorOrIcon'} = $icon;
    $shellExecInfo->{'fMask'} |= SEE_MASK_ICON;
    $shellExecInfo->{'fMask'} &= ~SEE_MASK_HMONITOR
}

sub directory($)
{

    my($shellCommand, $directory) = (shift, shift);

    $shellCommand->{'shell_execute_info'}->{lpDirectory} = $directory
}

sub class_name($)
{
    my ($shellCommand, $class_name) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'lpClass'} = $class_name;
    $shellExecInfo->{'fMask'} |= SEE_MASK_CLASSNAME;

    $shellExecInfo->{'hKeyClass'} = 0;
    $shellExecInfo->{'fMask'} &= ~SEE_MASK_CLASSKEY
}

sub class_key($)
{
    my ($shellCommand, $class_key) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'hKeyClass'} = $class_key;
    $shellExecInfo->{'fMask'} |= SEE_MASK_CLASSKEY;

    $shellExecInfo->{'lpClass'} = undef;
    $shellExecInfo->{'fMask'} &= ~SEE_MASK_CLASSNAME
}

sub id_list($)
{
    my ($shellCommand, $id_list) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'lpIDList'} = $id_list;
    $shellExecInfo->{'fMask'} |= SEE_MASK_IDLIST
}

sub invoke_id_list($)
{
    my ($shellCommand, $id_list) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'lpIDList'} = $id_list;
    $shellExecInfo->{'fMask'} |= SEE_MASK_INVOKEIDLIST
}

sub hinst_is_site($)
{
    my ($shellCommand, $serviceProvider) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'hInstApp'} = $serviceProvider;
    $shellExecInfo->{'fMask'} |= SEE_MASK_FLAG_HINST_IS_SITE
}

sub hotkey($)
{
    my($shellCommand, $hotkey) = (shift, shift);
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    $shellExecInfo->{'dwHotKey'} = $hotkey;
    $shellExecInfo->{'fMask'} |= SEE_MASK_HOTKEY
}

sub find_process_window
{
    my($package, $pid) = shift, shift;

    unless ($pid)
    {
	$ProcessID = GetCurrentProcessId() unless $ProcessID;   
	$pid = $ProcessID
    }

    my $hWnd = 0;
    my $wnd_pid = 0;

    while ($hWnd = FindWindowExA(0, $hWnd, undef, undef))
    {
	GetWindowThreadProcessId($hWnd, $wnd_pid);

	last if $wnd_pid == $pid
    }

    return $hWnd
}

sub check_hinstance
{
    my $shellExecInfo = (shift)->{'shell_execute_info'};

    if ($shellExecInfo->{'fMask'} & SEE_MASK_NOCLOSEPROCESS and $shellExecInfo->{'hInstApp'} <= 32)
    {
	die Win32::ShellExecute::Exception->new($shellExecInfo->{'hInstApp'})
    }
}

sub execute
{
    my $shellCommand = shift;
    my $shellExecInfo = $shellCommand->{'shell_execute_info'};

    return sub
    {
	co_initialize

	$shellExecInfo->{'hInstApp'} = 0 unless $shellExecInfo->{'fMask'} & SEE_MASK_FLAG_HINST_IS_SITE;
	$shellExecInfo->{'hProcess'} = 0;

	if (ShellExecuteExA($shellExecInfo))
	{
	    if ($shellExecInfo->{'fMask'} & SEE_MASK_NOCLOSEPROCESS and $shellExecInfo->{'hProcess'})
	    {
		Win32::SetLastError(0);
		my $subprocess_id = GetProcessId($shellExecInfo->{'hProcess'});
		my $last_error = Win32::GetLastError();

		CloseHandle($shellExecInfo->{'hProcess'});
		$shellExecInfo->{'hProcess'} = 0;

		if ($last_error)
		{
		    Win32::SetLastError($last_error);
		    $EXTENDED_OS_ERROR = $last_error;
		    return undef
		}

		return $subprocess_id
	    }

	    return true;
	}

	# $shellCommand->check_hinstance();
	$EXTENDED_OS_ERROR = Win32::GetLastError();
	return undef
    }
}

sub shell_execute
{
    return &{Win32::ShellExecute->new(@ARG)}()
}

return true
