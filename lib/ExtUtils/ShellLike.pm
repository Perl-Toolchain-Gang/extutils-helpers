package ExtUtils::Helpers;
use strict;
use warnings FATAL => 'all';
use Exporter 5.57 'import';
use Text::ParseWords 3.24 qw/shellwords/;

our @EXPORT_OK = qw/split_like_shell detildefy/;

sub unix_split_like_shell {
	my ($string) = @_;

	return if not defined $string;
	$string =~ s/^\s+|\s+$//g;
	return if not length $string;

	return shellwords($string);
}

sub windows_split_like_shell {
	# As it turns out, Windows command-parsing is very different from
	# Unix command-parsing.	Double-quotes mean different things,
	# backslashes don't necessarily mean escapes, and so on.	So we
	# can't use Text::ParseWords::shellwords() to break a command string
	# into words.	The algorithm below was bashed out by Randy and Ken
	# (mostly Randy), and there are a lot of regression tests, so we
	# should feel free to adjust if desired.

	local ($_) = @_;

	my @argv;
	return @argv unless defined && length;

	my $arg = '';
	my ($i, $quote_mode ) = ( 0, 0 );

	while ( $i < length ) {

		my $ch      = substr $_, $i, 1;
		my $next_ch = substr $_, $i+1, 1;

		if ( $ch eq '\\' && $next_ch eq '"' ) {
			$arg .= '"';
			$i++;
		} elsif ( $ch eq '\\' && $next_ch eq '\\' ) {
			$arg .= '\\';
			$i++;
		} elsif ( $ch eq '"' && $next_ch eq '"' && $quote_mode ) {
			$quote_mode = !$quote_mode;
			$arg .= '"';
			$i++;
		} elsif ( $ch eq '"' && $next_ch eq '"' && !$quote_mode &&
				( $i + 2 == length() || substr( $_, $i + 2, 1 ) eq ' ' )
			) { # for cases like: a"" => [ 'a' ]
			push @argv, $arg;
			$arg = '';
			$i += 2;
		} elsif ( $ch eq '"' ) {
			$quote_mode = !$quote_mode;
		} elsif ( $ch =~ /\s/ && !$quote_mode ) {
			push @argv, $arg if $arg;
			$arg = '';
			++$i while substr( $_, $i + 1, 1 ) =~ /\s/;
		} else {
			$arg .= $ch;
		}

		$i++;
	}

	push @argv, $arg if defined $arg && length $arg;
	return @argv;
}

sub unix_detildefy {
	my $value = shift;
	# tilde with optional username
	for ($value) {
		s{ ^ ~ (?= /|$)}          [ $ENV{HOME} || (getpwuid $>)[7] ]ex or # tilde without user name
		s{ ^ ~ ([^/]+) (?= /|$) } { (getpwnam $1)[7] || "~$1" }ex;        # tilde with user name
	}
	return $value;
}

sub windows_detildefy {
	my $value = shift;
	$value =~ s{ ^ ~ (?= [/\\] | $ ) }[$ENV{USERPROFILE}]x if $ENV{USERPROFILE};
	return $value;
}

sub vms_detildefy {
	my $arg = shift;

	# Apparently double ~ are not translated.
	return $arg if ($arg =~ /^~~/);

	# Apparently ~ followed by whitespace are not translated.
	return $arg if ($arg =~ /^~ /);

	if ($arg =~ /^~/) {
		my $spec = $arg;

		# Remove the tilde
		$spec =~ s/^~//;

		# Remove any slash following the tilde if present.
		$spec =~ s#^/##;

		# break up the paths for the merge
		my $home = VMS::Filespec::unixify($ENV{HOME});

		# In the default VMS mode, the trailing slash is present.
		# In Unix report mode it is not.  The parsing logic assumes that
		# it is present.
		$home .= '/' unless $home =~ m#/$#;

		# Trivial case of just ~ by it self
		if ($spec eq '') {
			$home =~ s#/$##;
			return $home;
		}

		my ($hvol, $hdir, $hfile) = File::Spec::Unix->splitpath($home);
		if ($hdir eq '') {
			 # Someone has tampered with $ENV{HOME}
			 # So hfile is probably the directory since this should be
			 # a path.
			 $hdir = $hfile;
		}

		my ($vol, $dir, $file) = File::Spec::Unix->splitpath($spec);

		my @hdirs = File::Spec::Unix->splitdir($hdir);
		my @dirs = File::Spec::Unix->splitdir($dir);

		unless ($arg =~ m#^~/#) {
			# There is a home directory after the tilde, but it will already
			# be present in in @hdirs so we need to remove it by from @dirs.

			shift @dirs;
		}
		my $newdirs = File::Spec::Unix->catdir(@hdirs, @dirs);

		$arg = File::Spec::Unix->catpath($hvol, $newdirs, $file);
	}
	return $arg;
}

no warnings 'once';
(*split_like_shell, *detildefy) =
	$^O eq 'MSWin32' ? (\&windows_split_like_shell, \&windows_detildefy) :
	$^O eq 'VMS' ? (\&unix_split_like_shell, \&vms_detildefy) :
	(\&unix_split_like_shell, \&unix_detildefy);

1;
