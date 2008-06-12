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
  print "entering\n";
  if ( $entering{''}++ ) {
    print "restarted\n";
    exit;
  }

  if ( my $tmp = shift @ARGV ) {
    open STDOUT, '>', $tmp
      or die "Can't open $tmp for writing: $!";
    open STDERR, '>&', 'STDOUT'
      or die "Can't redirect STDERR to STDOUT: $!";
  }

  $| = 1;

  system 'make';
  exit 1 unless 0 == $?;
}
use vars qw( %entering );
use strict;
use warnings;
use blib;
use Enbugger ();
use Enbugger::OnError '__DIE__';
# BEGIN { Enbugger::debug( 1 ) }
use B        qw( svref_2object     );
use B::Utils qw( walkoptree_simple );

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
    my $r = eleven() / 7;
    print "leaving seven\n";
    7;
}
sub eleven {
    $DB::single = 2;
    print "entering eleven\n";
    if ( $entering{eleven}++ ) {
	print "restarted eleven\n";
	return 11;
    }
    die;
    print "leaving eleven\n";
    11;
}

BEGIN {
    for my $nm (qw( two three five seven eleven )) {
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
}

two()

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
