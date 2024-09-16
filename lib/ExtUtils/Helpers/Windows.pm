package ExtUtils::Helpers::Windows;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use Config;
use Carp qw/carp croak/;
use ExtUtils::PL2Bat 'pl2bat';

sub make_executable {
	my $script = shift;
	if (-T $script && $script !~ / \. (?:bat|cmd) $ /x) {
		pl2bat(in => $script, update => 1);
	}
	return;
}

sub split_like_shell {
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

	m/\G\s*/gc;

	ARG: until ( pos == length ) {
		my $quote_mode;
		my $arg = '';
		CHAR: until ( pos == length ) {
			if ( m/\G((?:\\\\)+)(?=\\?(")?)/gc ) {
				if (defined $2) {
					$arg .= '\\' x (length($1) / 2);
				}
				else {
					$arg .= $1;
				}
			}
			elsif ( m/\G\\([\\|"])/gc ) {
				$arg .= $1;
			}
			elsif ( $quote_mode && m/\G""/gc ) {
				$quote_mode = !$quote_mode;
				$arg .= '"';
			}
			elsif ( m/\G"/gc ) {
				$quote_mode = !$quote_mode;
			}
			elsif ( !$quote_mode && m/\G\s+\z?/gc ) {
				last CHAR;
			}
			elsif ( m/\G(.)/gc ) {
				$arg .= $1;
			}
		}
		push @argv, $arg;
	}

	return @argv;
}

sub detildefy {
	my $value = shift;
	$value =~ s{ ^ ~ (?= [/\\] | $ ) }[$ENV{USERPROFILE}]x if $ENV{USERPROFILE};
	return $value;
}

1;

# ABSTRACT: Windows specific helper bits

=begin Pod::Coverage

make_executable
split_like_shell
detildefy

=end Pod::Coverage

=cut
