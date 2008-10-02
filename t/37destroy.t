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
use Test::More tests => 27;
use FindBin '$Bin';
use lib $Bin;
use Test::Enbugger::Restarts 'test_restart';

my $test_program = $0;
$test_program =~ s/\.t\z/.pl/
    or die "Can't guess test program name from harness name";

TODO: {
    local $TODO = 'I have the flow control for destruction all wrong';

for my $test (
    { nth => -2,
      croak => 0,
      expect => qr/Cannot return -2 frames/ },
    { nth => -1,
      croak => 0,
      expect => qr/Cannot return -1 frames/ },
    { nth => 0,
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'leaving X::DESTROY',
		   'leaving seven',
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 1,
      todo_croak => q(panic: POPSTACK),
      todo_restart => q(The interpreter restarts seven, not X::DESTROY),
      restart => 'X::DESTROY',
      todo_actions => q(The wrong flow),
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'restarted X::DESTROY',
		   'leaving seven',
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 2,
      todo_croak => 'Bus error',
      restart => 'seven',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'entering seven',
		   'restarted seven',
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 3,
      todo_croak => 'panic: POPSTACK',
      restart => 'five',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'entering five',
		   'restarted five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 4,
      todo_croak => 'panic: POPSTACK',
      restart => 'three',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'entering three',
		   'restarted three',
		   'leaving two' ] },
    { nth => 5,
      todo_croak => 'panic: POPSTACK',
      restart => 'two',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering X::DESTROY',
		   'entering two',
		   'restarted two' ] },
    { nth => 6,
      todo_croak => 'panic: POPSTACK',
      croak => 1,
      expect => qr/Can't restart main/ },
    { nth => 7,
      croak => 1,
      todo_expect => 'Popping to wrong level',
      expect => qr/Can't pop to frame 7/ },
    { nth => 8,
      croak => 1,
      expect => qr/Can't pop to frame 8/ }
    ) {
    
    
    test_restart( {
	program => $test_program,
	%$test
		  } );
}
}

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
