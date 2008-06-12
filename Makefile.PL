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
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME                => 'Enbugger::Restarts',
	      VERSION_FROM        => 'lib/Enbugger/Restarts.pm',
	      ABSTRACT_FROM       => 'lib/Enbugger/Restarts.pod',
	      AUTHOR              => 'Whitepages.com, Inc <whitepage@cpan.org>',
	      LICENSE             => 'perl',
	      PREREQ_PM => {
			    'Test::More' => 0,
			    'Enbugger'   => '2.000',
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Enbugger-Restarts-*' },
	     );

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
