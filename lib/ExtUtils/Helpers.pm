package ExtUtils::Helpers;
use strict;
use warnings FATAL => 'all';
use Exporter 5.57 'import';

use File::Basename qw/basename dirname/;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/splitpath splitdir canonpath/;
use Pod::Man;

use ExtUtils::Helpers::Unix ();
use ExtUtils::Helpers::Windows ();

our @EXPORT_OK = qw/build_script make_executable split_like_shell man1_pagename manify man3_pagename/;
our $VERSION = 0.010;

BEGIN {
	my $package = "ExtUtils::Helpers::" . ($^O eq 'MSWin32' ? 'Windows' : 'Unix');
	$package->import();
}

sub build_script {
	return $^O eq 'VMS' ? 'Build.com' : 'Build';
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

sub man3_pagename {
	my $filename = shift;
	my ($vols, $dirs, $file) = splitpath(canonpath($filename));
	$file = basename($file, qw/.pm .pod/);
	my @dirs = grep { length } splitdir($dirs);
	shift @dirs if $dirs[0] eq 'lib';
	my $separator = $separator{$^O} || '::';
	return join $separator, @dirs, "$file.3pm";
}

sub manify {
	my ($input_file, $output_file, $section, $opts) = @_;
	my $dirname = dirname($output_file);
	mkpath($dirname, $opts->{verbose}) if not -d $dirname;
	Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
	print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
	return;
}

1;

# ABSTRACT: Various portability utilities for module builders

__END__

=head1 SYNOPSIS

 use ExtUtils::Helpers qw/build_script make_executable split_like_shell/;

 unshift @ARGV, split_like_shell($ENV{PROGRAM_OPTS});
 write_script_to(build_script());
 make_executable(build_script());

=head1 DESCRIPTION

This module provides various portable helper functions for module building modules.

=func build_script()

This function returns the appropriate name for the Build script on the local platform.

=func make_executable($filename)

This makes a perl script executable.

=func split_like_shell($string)

This function splits a string the same way as the local platform does.

=func man1_pagename($filename)

Returns the man page filename for a script.

=func man3_pagename($filename)

Returns the man page filename for a Perl library.

=func manify($input_filename, $output_file, $section, $opts)

Create a manpage for the script in C<$input_filename> as C<$output_file> in section C<$section>

=cut
