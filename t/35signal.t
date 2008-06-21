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

for my $test (
    { nth => -2,
      croak => 1,
      expect => qr/^Cannot return -\d+ frames at \S+ line \d+\./m },
    { nth => -1,
      croak => 1,
      expect => qr/^Cannot return -\d+ frames at \S+ line \d+\./m },
    { nth => 0,
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   'leaving signal',
		   'leaving seven',
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 1,
      todo => 'Not working or test is wrong',
      restart => 'signal',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   'entering signal',
		   'restarted signal',
		   'leaving signal',
		   'leaving seven',
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 2,
      todo => 'Not working or test is wrong',
      restart => 'seven',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   'entering seven',
		   'restarted seven',
		   # Why no 'leaving seven'
		   'leaving five',
		   'leaving three',
		   'leaving two' ] },
    { nth => 3,
      todo => 'Not working or test is wrong',
      restart => 'five',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   'entering five',
		   'restarted five',
		   # Why no 'leaving five'
		   'leaving three',
		   'leaving two' ] },
    { nth => 4,
      todo => 'Not working or test is wrong',
      restart => 'three',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   # Why no 'leaving three'
		   'entering three',
		   'restarted three',
		   'leaving two' ] },
    { nth => 5,
      todo => 'Not working or test is wrong',
      restart => 'two',
      actions => [ 'entering two',
		   'entering three',
		   'entering five',
		   'entering seven',
		   'entering signal',
		   # Why no 'leaving two'
		   'entering two',
		   'restarted two' ] },
    { nth => 6,
      todo => 'accidentally works?',
      #todo => 'Not working or test is wrong',
      croak => 1,
      expect => qr/^TODO: Can't restart main/m },
    { nth => 7,
      croak => 1,
      expect => qr/piddle/i },
    { nth => 8,
      croak => 1,
      expect => qr/piddle/i }
    ) {
    
    
    test_restart( {
	program => $test_program,
	%$test
		  } );
}

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
