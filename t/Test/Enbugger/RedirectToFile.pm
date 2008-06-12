package Test::Enbugger::RedirectToFile;

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

use strict;
use warnings;
use vars qw( $REDIRECTED );

BEGIN {
    # Redirect only once. If by chance I find my self re-running this
    # module, avoid messing with STD(OUT|ERR).
    if ( not $REDIRECTED ) {
	$REDIRECTED = 1;
	
	if ( @ARGV ) {
	    my $tmp = shift @ARGV;
	    open STDOUT, '>', $tmp
		or die "Can't open $tmp for writing: $!";
	    open STDERR, '>&', 'STDOUT'
		or die "Can't redirect STDERR to STDOUT: $!";
	}
    }
}

() = -.0

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
