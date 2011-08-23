package ExtUtils::Helpers::Unix;
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell/;

use Text::ParseWords 3.24 qw/shellwords/;
use ExtUtils::MakeMaker;

sub _make_executable {
  # Perl's chmod() is mapped to useful things on various non-Unix
  # platforms, so we use it everywhere even though it looks
  # Unixish.

  foreach (@_) {
    my $current_mode = (stat $_)[2];
    chmod $current_mode | oct(111), $_;
  }
}

sub make_executable {
	ExtUtils::MM->fixin($_) for grep { -T } @_;
	goto &_make_executable
};

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
