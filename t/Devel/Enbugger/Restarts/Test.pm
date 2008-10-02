package Devel::Enbugger::Restarts::Test;

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

package DB;

# Choosing which parts are enabled.

# TODO: do I need to test with both DB::sub and DB::DB enabled?

sub useSub { $main::testing and $main::this_time and defined $main::sub }
sub useDB  { $main::testing and $main::this_time and defined $main::DB }

sub sub {
    if ( useSub() ) {
	print "restarting DB::sub\n" if $main::entering{'DB::sub'}++;
	print "entering DB::sub\n";
    }

    if ( $main::goto ) {
	goto &$DB::sub;
    }
    else {
	return &$DB::sub;
    }
}

sub DB {
    if ( useDB() ) {
	# TODO: almost certainly, this $enterin{...}++ test is wrong.
	print "restarting DB::DB\n" if $main::entering{'DB::DB'}++;
	print "entering DB::DB\n";

	# TODO: is this safe at all???
	# DB::restart_at( $main::DB );
	
	print "leaving DB::DB\n";
    }
}

() = -.0

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
