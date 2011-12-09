package ExtUtils::Helpers::Unix;
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell/;

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

1;

__END__

# ABSTRACT: Unix specific helper bits

=begin Pod::Coverage

make_executable
split_like_shell

=end Pod::Coverage

=cut
