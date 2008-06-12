package Enbugger::Restarts;

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2008 WhitePages.com, Inc. with primary development by
# Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

use warnings;
use strict;

use Enbugger;

use XSLoader ();
use vars qw( $VERSION );

BEGIN {
    $VERSION = '0.01_01';
    XSLoader::load( __PACKAGE__, $VERSION );

    # A word on aliases:
    #   Install command aliases for the debugger shell.
    #
    #   Each alias is actually a bit of code that will be compiled
    #   into the middle of a sub{$code} function and then called
    #   whenever the command matches.
    #
    #   The result of running the code is then evaled. The following
    #   code translates our user's shell commands into an alternate
    #   command.

    # Aliases the command restart_at(N) to rat(N) for the perl5db.pl
    # debugger.
    $DB::alias{rat} = 's/^\s*rat\s*(.+)/DB::safe_restart_at($1)/';
}

() = -.0;

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
