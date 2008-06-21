#!perl

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
use Test::More tests => 48;
use FindBin '$Bin';
use lib $Bin;
use Test::Enbugger::Restarts 'test_restart';

my $test_program = $0;
$test_program =~ s/\.t\z/.pl/
    or die "Can't guess test program name from harness name";

use constant NO_WORKY => q(Can't restart from inside debuggers);

my @tests = (
	     { nth => 'sub=-2',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/^Cannot return -2 frames at \S+ line \d+\./m },
	     { nth => 'sub=-1',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/^Cannot return -1 frames at \S+ line \d+\./m },
	     { nth => 'sub=0',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::sub',
			    'leaving DB::sub',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=1',
	       todo => 'todo',
	       restart => 'seven',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering seven',
			    'entering DB::sub',
			    'restarted seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=2',
	       todo => 'todo',
	       restart => 'five',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering five',
			    'entering DB::sub',
			    'restarted five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=3',
	       todo => 'todo',
	       restart => 'three',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::sub',
			    'entering three',
			    'restarted three',
			    'entering five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=4',
	       todo => 'todo',
	       restart => 'two',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::sub',
			    'entering two',
			    'restarted two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=5',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/^TODO: Can't restart main at \S+ line \d+\.$/m },
	     { nth => 'sub=6',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/piddle/i },
	     { nth => 'sub=7',
	       croak => 1,
	       todo => 'todo',
	       expect => qr/piddle/i },
	     { nth => 'sub=-2',
	       croak => 1,
	       todo => 'todo',
	       expect => qr/^Cannot return -2 frames at \S+ line \d+\./m },


	     { nth => 'DB=-1',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/^Cannot return -1 frames at \S+ line \d+\./m },
	     { nth => 'DB=0',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::DB',
			    'leaving DB::DB',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'DB=1',
	       restart => 'seven',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering seven',
			    'entering DB::DB',
			    'restarted seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'DB=2',
	       restart => 'five',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering five',
			    'entering DB::DB',
			    'restarted five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'DB=3',
	       restart => 'three',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::DB',
			    'entering three',
			    'restarted three',
			    'entering five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'DB=4',
	       restart => 'two',
	       todo => 'todo',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::DB',
			    'entering two',
			    'restarted two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'DB=5',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/^TODO: Can't restart main at \S+ line \d+\.$/m },
	     { nth => 'DB=6',
	       todo => 'todo',
	       croak => 1,
	       expect => qr/piddle/i },
	     { nth => 'DB=7',
	       croak => 1,
	       todo => 'todo',
	       expect => qr/piddle/i },
	    );

for my $test ( @tests ) {
    
    test_restart( {
		   program => $test_program,
		   perl_args => '-d:Enbugger::Restarts::Test',
		   %$test,
		  } );
}

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
