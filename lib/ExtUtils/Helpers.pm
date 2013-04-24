package ExtUtils::Helpers;
use strict;
use warnings FATAL => 'all';
use Exporter 5.57 'import';

use File::Basename qw/basename/;
use File::Spec::Functions qw/splitpath canonpath abs2rel splitdir/;
use Module::Load;

our @EXPORT_OK = qw/build_script make_executable split_like_shell man1_pagename man3_pagename detildefy/;

BEGIN {
	my %impl_for = ( MSWin32 => 'Windows', VMS => 'VMS');
	my $package = 'ExtUtils::Helpers::' . ($impl_for{$^O} || 'Unix');
	load($package);
	$package->import();
}

sub man1_pagename {
	my $filename = shift;
	return basename($filename).'.1';
}

my %separator = (
	MSWin32 => '.',
	VMS => '__',
	os2 => '.',
	cygwin => '.',
);
my $separator = $separator{$^O} || '::';

sub man3_pagename {
	my ($filename, $base) = @_;
	$base ||= 'lib';
	my ($vols, $dirs, $file) = splitpath(canonpath($filename));
	$file = basename($file, qw/.pm .pod/);
	$dirs = abs2rel($dirs, $base);
	return join $separator, splitdir($dirs), "$file.3pm";
}

1;

# ABSTRACT: Various portability utilities for module builders

=encoding utf-8

=head1 SYNOPSIS

 use ExtUtils::Helpers qw/build_script make_executable split_like_shell/;

 unshift @ARGV, split_like_shell($ENV{PROGRAM_OPTS});
 write_script_to('Build');
 make_executable('Build');

=head1 DESCRIPTION

This module provides various portable helper functions for module building modules.

=func build_script()

This function returns the appropriate name for the Build script on the local platform.

=func make_executable($filename)

This makes a perl script executable.

=func split_like_shell($string)

This function splits a string the same way as the local platform does.

=func detildefy($path)

This function substitutes a tilde at the start of a path with the users homedir in an appropriate manner.

=func man1_pagename($filename)

Returns the man page filename for a script.

=func man3_pagename($filename, $basedir)

Returns the man page filename for a Perl library.

=func manify($input_filename, $output_file, $section, $opts)

Create a manpage for the script in C<$input_filename> as C<$output_file> in section C<$section>

=head1 ACKNOWLEDGEMENTS

Olivier Mengué and Christian Walde made C<make_executable> work on Windows.

=cut
