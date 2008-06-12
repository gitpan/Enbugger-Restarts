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

BEGIN {
    my $nth_input = shift(@ARGV) || 'warn=0';
    $nth_input =~ /^(\w+)=([-\d]+)\z/
      or die "Invalid nth [$nth]";
    my $target = "main::$1";
    $$target = $nth = $2;

    $| = 1;
}

use strict;
use warnings;
use vars qw( $nth %entering $die $warn );

use B        qw( svref_2object     );
use B::Utils qw( walkoptree_simple );

# from t/
use Test::Enbugger::RedirectToFile ();
BEGIN {
    print "entering\n";
    if ( $::entering{''}++ ) {
	print "restarted\n";
	exit;
    }
}

use blib;
use Enbugger::Restarts ();
BEGIN { Enbugger::Restarts::debug( 1 ) }

sub two {
    print "entering two\n";
    if ( $entering{two}++ ) {
	print "restarted two\n";
	return 2;
    }
    my $r = 2 + three();
    print "leaving two\n";
    $r
}

sub three {
    print "entering three\n";
    if ( $entering{three}++ ) {
	print "restarted three\n";
	return 3;
    }
    my $r = 3 - five();
    print "leaving three\n";
    $r
}
sub five {
    print "entering five\n";
    if ( $entering{five}++ ) {
	print "restarted five\n";
	return 5;
    }
    my $r = 5 * seven();
    print "leaving five\n";
    5
}
sub seven {
    print "entering seven\n";
    if ( $entering{seven}++ ) {
	print "restarted seven\n";
	return 7;
    }

    if ( $warn ) {
	$SIG{__WARN__} = \ &signal;
	warn 7;
    }
    elsif ( $die ) {
	$SIG{__DIE__} = \ &signal;
	die 7;
    }
    print "leaving seven\n";
    7
}
sub signal {
    print "entering signal\n";
    if ( $entering{'signal'}++ ) {
	print "restarted signal\n";
	return;
    }
    my $r = DB::restart_at( $nth );
    print "leaving signal\n";
    $r
}

for my $nm (qw( two three five seven signal )) {
  my $ref = \&$nm;
  my $cv  = svref_2object( $ref );
  
  local $" = ', ';
  my @ops;
  walkoptree_simple( $cv->ROOT,
		     sub { push @ops, sprintf '0x%x', ${$_[0]} } );
  printf "$nm = {@ops}\n";

  printf "$nm $_=0x%x\n", ${$cv->$_}
    for qw( START ROOT );
}

two()

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
