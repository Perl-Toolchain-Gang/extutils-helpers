package ExtUtils::Helpers::Unix;
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use Text::ParseWords 3.24 qw/shellwords/;
use ExtUtils::MakeMaker;

sub make_executable {
	my $file = shift;
	my $current_mode = (stat $file)[2] + 0;
	ExtUtils::MM->fixin($file) if -T $file;
	chmod $current_mode | oct(111), $file;
	return;
}

sub split_like_shell {
  my ($string) = @_;

  return if not defined $string;
  $string =~ s/^\s+|\s+$//g;
  return if not length $string;

  return shellwords($string);
}

sub detildefy {
	my $value = shift;
	# tilde with optional username
	for ($value) {
		s{ ^ ~ (?= /|$)}          [ $ENV{HOME} || (getpwuid $>)[7] ]ex or # tilde without user name
		s{ ^ ~ ([^/]+) (?= /|$) } { (getpwnam $1)[7] || "~$1" }ex;        # tilde with user name
	}
	return $value;
}

1;

# ABSTRACT: Unix specific helper bits

__END__

=begin Pod::Coverage

make_executable
split_like_shell
detildefy

=end Pod::Coverage

=cut
