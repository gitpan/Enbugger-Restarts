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
sub sub {
    print "entering DB::sub\n" if $main::testing;
    if (defined $main::sub and $main::this_time ) {
	restart_at( $main::sub );
    }

    
    if ( wantarray ) {
	my @result = &$sub;
	print "returning from DB::sub\n" if $main::testing;
	return @result;
    }
    elsif ( defined wantarray ) {
	my $result = &$sub;
	print "returning from DB::sub\n" if $main::testing;
	return $result;
    }
    else {
	&$sub;
	print "returning from DB::sub\n" if $main::testing;
	return;
    }
}

sub DB {
    if ( defined $main::DB and $main::this_time ) {
	print "entering DB::DB\n" if $main::testing;
	restart_at( $main::DB );
	print "returning DB::DB\n" if $main::testing;
    }
}

() = -.0

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
