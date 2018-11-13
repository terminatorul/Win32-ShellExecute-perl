use warnings;
use strict;
use English;
use Test::More tests => 10;
use FindBin;
use File::Spec::Unix;
use lib File::Spec::Unix->catdir($FindBin::Bin, File::Spec::Unix->updir(), 'lib');
use Win32::CmdQuote::Simple;

use constant false => !!undef;
use constant true  => !undef;

ok((Win32::CmdQuote::Simple::quote_args '&')[0] eq '"&"', 'metacharacter 1: & (ampersand)');
ok((Win32::CmdQuote::Simple::quote_args ' ')[0] eq '" "', 'metacharacter 2:   (space)');
ok((Win32::CmdQuote::Simple::quote_args '+')[0] eq '"+"', 'metacharacter 3: + (plus)');
ok((Win32::CmdQuote::Simple::quote_args 'directory names\\\\')[0] eq '"directory names"\\\\', 'trailing backslashes');

local $EVAL_ERROR = undef;
eval
{
    Win32::CmdQuote::Simple::quote_args 'name: "string value"'
};

ok($EVAL_ERROR =~ m/unsafe command argument/, 'die on unsafe command argument');

$Win32::CmdQuote::Simple::QUOTE_ARGS = false;

ok((Win32::CmdQuote::Simple::quote_args '&')[0] eq '&', 'pass-through metacharacter 1: & (ampersand)');
ok((Win32::CmdQuote::Simple::quote_args ' ')[0] eq ' ', 'pass-through metacharacter 2:   (space)');
ok((Win32::CmdQuote::Simple::quote_args '+')[0] eq '+', 'pass-through metacharacter 3: + (plus)');
ok((Win32::CmdQuote::Simple::quote_args 'directory names\\\\')[0] eq 'directory names\\\\', 'pass-through traling backslashes');

local $EVAL_ERROR = undef;
eval
{
    Win32::CmdQuote::Simple::quote_args 'name: "string value"'
};

ok(!$EVAL_ERROR, 'pass-through unsafe command argument');

