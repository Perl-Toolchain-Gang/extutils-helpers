#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec::Functions qw/catfile/;
use ExtUtils::Helpers qw/man1_pagename man3_pagename/;

my %separator = (
	MSWin32 => '.',
	VMS => '__',
	os2 => '.',
	cygwin => '.',
);
my $sep = $separator{$^O} || '::';

is man1_pagename('script/foo'), 'foo.1', 'man1_pagename';

is man3_pagename(catfile(qw/lib ExtUtils Helpers.pm/)), join($sep, qw/ExtUtils Helpers.3pm/), 'man3_pagename';
is man3_pagename(catfile(qw/lib ExtUtils Helpers Unix.pm/)), join($sep, qw/ExtUtils Helpers Unix.3pm/), 'man3_pagename';

done_testing;
