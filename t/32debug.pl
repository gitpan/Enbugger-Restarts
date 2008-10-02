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
    my $nth_input = shift(@ARGV) || 'sub=0';
    $nth_input =~ /^(\w+)=([-\d]+)\z/
      or die "Invalid nth [$nth] . Pattern should match /^(?:sub|DB)=-?\d+\z/";
    my $target = "main::$1";
    $$target = $nth = $2;
    
    if ( $ARGV[0] eq 'goto' ) {
	$main::goto = 1;
	shift @ARGV;
    }
    

    $| = 1;
}

use strict;
use warnings;
use vars qw( $nth %entering $this_time );

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
    return $r;
}

sub three {
    print "entering three\n";
    if ( $entering{three}++ ) {
	print "restarted three\n";
	return 3;
    }
    my $r = 3 - five();
    print "leaving three\n";
    return $r;
}
sub five {
    print "entering five\n";
    if ( $entering{five}++ ) {
	print "restarted five\n";
	return 5;
    }
    my $r = 5 * seven();
    print "leaving five\n";
    return 5;
}
sub seven {
    print "entering seven\n";
    if ( $entering{seven}++ ) {
	print "restarted seven\n";
	return 7;
    }

    local $main::this_time = 1;
    die 'possible infinite loop detected' if $main::restart_counter++ > 100;
    DB::restart_at( $main::nth );

    print "leaving seven\n";
    return 7;
}

for my $nm (qw( two three five seven DB::sub DB::DB )) {
  my $ref = \&$nm;
  my $cv  = B::svref_2object( $ref );

  my @ops;
  walkoptree_simple( $cv->ROOT,
		     sub { push @ops, sprintf '0x%x', ${$_[0]} } );
  print "$nm = {".join(', ',@ops)."}\n";

  printf "$nm $_=0x%x\n", ${$cv->$_}
    for qw( START ROOT );
}

$main::testing = 1;
two();

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
