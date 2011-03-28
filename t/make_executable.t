#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Config;
use Test::More tests => 2;
use ExtUtils::Helpers qw/make_executable/;
use Cwd qw/cwd/;

my $filename = 'test_exec.pl';

open my $out, '>', $filename;
print $out "#! perl \nexit 0;\n";
close $out;

make_executable($filename);

{
	my $cwd = cwd;
	local $ENV{PATH} = join $Config{path_sep}, $cwd, $ENV{PATH};
	my $ret = system $filename;
	is $ret, 0, 'test_exec executed successfully';
}

SKIP: {
	skip 'No batch file on non-windows', 1 if $^O ne 'MSWin32';
	my $ret = system 'test_exec';
	is $ret, 0, 'test_exec.bat executed successfully';
}

unlink 'test_exec.pl'
