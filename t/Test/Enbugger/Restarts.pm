package Test::Enbugger::Restarts;

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

use FindBin        qw( $Bin      );
use Test::Enbugger qw( read_file );
use Data::Dumper   qw( Dumper    );
use Test::More ();
use File::Temp ();

use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS $TODO );

BEGIN {
    *import = \ &Exporter::import;
    @EXPORT_OK = qw( test_restart );
    $EXPORT_TAGS{all} = [ @EXPORT, @EXPORT_OK ];
    $EXPORT_TAGS{test} = [ qw( test_restart ) ];
}

sub test_restart {
    my ( $test ) = @_;

    my $tmp = File::Temp->new( UNLINK => 1 );
    my $tmp_nm = $tmp->filename;
    
    # TODO: extract the directory from $test->{program} and use
    # that as input to -I instead of FindBin's $Bin.
    
    # Run the program and hope it wrote its information to the
    # temporary file I named for it.
    my @args = (
		$^X,
		'-I', $Bin,
	       );
    if ( ref $test->{perl_args} ) {
	push @args, @{ $test->{perl_args} };
    } elsif ( defined $test->{perl_args} ) {
	push @args, $test->{perl_args};
    }
    push @args, (
		 $test->{program},
		 $test->{nth},
		 $tmp_nm,
		);
    
    local $TODO;
  TODO: {
      SKIP: {
	    Test::More::skip $test->{skip}, 1 if exists $test->{skip};
	    $TODO = $test->{todo} if exists $test->{todo};
	    system { $args[0] } @args;
	    Test::More::cmp_ok( 0+$?,
				( $test->{croak} ? '!=' : '==' ),
				0, "$test->{program} $test->{nth} $tmp_nm" );
	}
    }
    
    # Accept the results.
    my $t = read_file( $tmp_nm );
    # diag( $t );
    
    # Interprete the results.
    
    if ( $test->{expect} ) {
      TODO: {
	  SKIP: {
		Test::More::skip $test->{skip}, 1 if $test->{skip};
		$TODO = $test->{todo} if exists $test->{todo};
		Test::More::like( $t, $test->{expect}, "Expected $test->{expect}" );
	    }
	}
    }
    
    # Try to restart to the proper location
    if ( $test->{restart} ) {
	my $expected_restart_sub = $test->{restart};
	
	# Map (Opcode -> Function).
	my %ops_2sub;
	pos( $t ) = undef;
	while ( $t =~ /^(\S+) = \{([^\}]+)\}$/gm ) {
	    my $sub     = $1;
	    my $ops_str = $2;	# ex: '0x12345, 0x23456'
	    
	    my @ops = $ops_str =~ /0x([a-f\d]+)/gi;
	    for my $op ( @ops ) {
		$ops_2sub{$op} = $sub;
	    }
	}
	    
	# Restarted @ which opcode?
	if ( $t =~ /^cxstack_ix=-?\d+ cxix=-?\d+ cv=0x[\da-f]+ retop=\w+\(0x([\da-f]+)\)$/m ) {
	    my $restart_op = $1;
		
	    # Restarted in which function?
	    my $restart_sub = $ops_2sub{ $restart_op || '' };
		
	  TODO: {
	      SKIP: {
		    Test::More::skip( $test->{skip}, 1 ) if $test->{skip};
		    $TODO = $test->{todo} if exists $test->{todo};
		    Test::More::is( $restart_sub, $expected_restart_sub, "Returned to $expected_restart_sub" );
		}
	    }
	}
	else {
	    Test::More::fail( "Debugging was disabled." );
	}
    }
	
    # The proper control flow was observed.
    if ( $test->{actions} ) {
	local $Data::Dumper::Varname = 'actions';
	local $Data::Dumper::Terse   = 2;
	my @actions = $t =~ /^((?:entering|leaving|restarted) .+)/gm;
      TODO: {
	  SKIP: {
		Test::More::skip($test->{skip},1) if $test->{skip};
		$TODO = $test->{todo} if exists $test->{todo};
		Test::More::is( Dumper( \ @actions ),
				Dumper( $test->{actions} ),
				"Proper control flow for nth $test->{nth}" );
	    }
	}
    }
    
    return;
}

() = -.0;


## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
