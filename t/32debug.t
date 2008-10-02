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
use Test::More tests => 49;
use FindBin '$Bin';
use lib $Bin;
use Test::Enbugger::Restarts 'test_restart';

my $test_program = $0;
$test_program =~ s/\.t\z/.pl/
    or die "Can't guess test program name from harness name";

use constant NO_WORKY => q(Can't restart from inside debuggers);

TODO: {
    local $TODO = 'need tests for goto &$DB::sub';
    fail( $TODO );
}

my $DB = '(?mx:
    entering\ DB::DB\
    leaving\ DB::DB\
)';

my @tests = (
	     { nth => 'sub=-2',
	       croak => 1,
	       expect => qr/Cannot return -2 frames/ },
	     { nth => 'sub=-1',
	       croak => 1,
	       expect => qr/Cannot return -1 frames/ },
	     { nth => 'sub=0',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::sub',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=1',
	       todo_actions => q(Doesn't seem to restart from the beginning properly),
	       restart => 'seven',
	       actions => [ 'entering two',
			    'entering three',
			    'entering five',
			    'entering seven',
			    'entering DB::sub',
			    'restarted seven',
			    'leaving seven',
			    'leaving five',
			    'leaving three',
			    'leaving two' ] },
	     { nth => 'sub=2',
	       restart => 'five',
	       todo_actions => q(Doesn't seem to restart from the beginning properly),
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
	       restart => 'three',
	       todo_actions => q(Doesn't seem to restart from the beginning properly),
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
	       restart => 'two',
	       todo_actions => q(Doesn't seem to restart from the beginning properly),
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
	       croak => 1,
	       expect => qr/Can't restart main/ },
	     { nth => 'sub=6',
	       croak => 1,
	       expect => qr/Can't pop to frame 6/ },
	     { nth => 'sub=7',
	       croak => 1,
	       expect => qr/Can't pop to frame 7/ },


	     { nth => 'DB=-2',
	       croak => 1,
	       expect => qr/Cannot return -2 frames/ },
	     { nth => 'DB=-1',
	       croak => 1,
	       expect => qr/Cannot return -1 frames/ },
	     { nth => 'DB=0',
	       actions_rx => qr/
                   entering\ two\n
		   entering\ three\n
		   entering\ five\n
		   $DB*
		   entering\ seven\n
		   $DB*
		   leaving\ seven\n
		   $DB*
		   leaving\ five\n
		   leaving\ three\n
		   leaving\ two\n\z/mx },
	     { nth => 'DB=1',
	       todo => 'Infinite loop',
	       restart => 'seven',
	       actions_rx => qr/
                   entering\ two\n
		   entering\ three\n
		   entering\ five\n
                   $DB*
		   entering\ seven\n
                   $DB*
		   entering\ seven\n
                   $DB*
		   restarted\ seven\n
                   $DB*
		   leaving\ five\n
		   leaving\ three\n
		   leaving\ two\n\z/mx },
	     { nth => 'DB=2',
	       todo => 'Infinite loop',
	       restart => 'five',
	       actions_rx => qr/
                   entering\ two\n
		   entering\ three\n
		   entering\ five\n
                   $DB*
		   entering\ seven\n
                   $DB*
		   entering\ five\n
                   $DB*
		   restarted\ five\n
                   $DB*
		   leaving\ three\n
		   leaving\ two\n\z/mx },
	     { nth => 'DB=3',
	       todo => 'Infinite loop',
	       restart => 'three',
	       actions_rx => qr/
                   entering\ two\n
		   entering\ three\n
		   entering\ five\n
                   $DB*
                   entering\ seven\n
                   $DB*
		   entering\ three\n
                   $DB*
		   restarted\ three\n
                   $DB*
		   leaving\ two\n\z/mx },
	     { nth => 'DB=4',
	       todo => 'Infinite loop',
	       restart => 'two',
	       actions_rx => qr/
                   entering\ two\n
		   entering\ three\n
		   entering\ five\n
                   $DB*
		   entering\ seven\n
                   $DB*
		   entering\ two\n
                   $DB*
		   restarted\ two\n
                   $DB*\z/mx },
	     { nth => 'DB=5',
	       croak => 1,
	       expect => qr/Can't restart main/ },
	     { nth => 'DB=6',
	       croak => 1,
	       expect => qr/Can't pop to frame 6/ },
	     { nth => 'DB=7',
	       croak => 1,
	       expect => qr/Can't pop to frame 7/ },
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
