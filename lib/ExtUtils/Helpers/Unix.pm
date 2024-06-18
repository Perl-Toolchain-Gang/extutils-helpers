package ExtUtils::Helpers::Unix;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use Carp qw/croak/;
use Config;
use Text::ParseWords 3.24 qw/shellwords/;

my $layer = $] >= 5.008001 ? ":raw" : "";

sub make_executable {
	my $filename = shift;
	my $current_mode = (stat $filename)[2] + 0;
	if (-T $filename) {
		open my $fh, "<$layer", $filename;
		my @lines = <$fh>;
		if (@lines and $lines[0] =~ s{ \A \#! \s* (?:/\S+/)? perl \b (.*) \z }{$Config{startperl}$1}xms) {
			open my $out, ">$layer", "$filename.new" or croak "Couldn't open $filename.new: $!";
			print $out @lines;
			close $out;
			rename $filename, "$filename.bak" or croak "Couldn't rename $filename to $filename.bak";
			rename "$filename.new", $filename or croak "Couldn't rename $filename.new to $filename";
			unlink "$filename.bak";
		}
	}
	chmod $current_mode | oct(111), $filename;
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
