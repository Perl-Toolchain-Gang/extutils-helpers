package ExtUtils::Helpers::Windows;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable detildefy/;

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
