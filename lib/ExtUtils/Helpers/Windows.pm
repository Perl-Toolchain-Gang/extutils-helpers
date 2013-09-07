package ExtUtils::Helpers::Windows;
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable split_like_shell detildefy/;

use Config;
use Carp qw/carp croak/;

sub make_executable {
	my $script = shift;
	if (-T $script && $script !~ / \. (?:bat|cmd) $ /x) {
		_pl2bat(in => $script, update => 1);
	}
	return;
}

# This routine was copied almost verbatim from the 'pl2bat' utility
# distributed with perl. It requires too much voodoo with shell quoting
# differences and shortcomings between the various flavors of Windows
# to reliably shell out
sub _pl2bat {
	my %opts = @_;

	# NOTE: %0 is already enclosed in doublequotes by cmd.exe, as appropriate
	$opts{ntargs}    = '-x -S %0 %*';
	$opts{otherargs} = '-x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9';

	$opts{stripsuffix} = qr/\.plx?/ unless exists $opts{stripsuffix};

	if (not exists $opts{out}) {
		$opts{out} = $opts{in};
		$opts{out} =~ s/$opts{stripsuffix}$//i;
		$opts{out} .= '.bat' unless $opts{in} =~ /\.bat$/i or $opts{in} eq '-';
	}

	my $head = <<"EOT";
	\@rem = '--*-Perl-*--
	\@echo off
	if "%OS%" == "Windows_NT" goto WinNT
	perl $opts{otherargs}
	\@set ErrorLevel=%ErrorLevel%
	goto endofperl
	:WinNT
	perl $opts{ntargs}
	\@set ErrorLevel=%ErrorLevel%
	if NOT "%COMSPEC%" == "%SystemRoot%\\system32\\cmd.exe" goto endofperl
	if %errorlevel% == 9009 echo You do not have Perl in your PATH.
	goto endofperl
	\@rem ';
EOT

	$head =~ s/^\s+//gm;
	my $headlines = 2 + ($head =~ tr/\n/\n/);
	my $tail = <<'EOT';
	__END__
	:endofperl
	@"%COMSPEC%" /c exit /b %ErrorLevel%
EOT
	$tail =~ s/^\s+//gm;

	my $linedone = 0;
	my $taildone = 0;
	my $linenum = 0;
	my $skiplines = 0;

	my $start = $Config{startperl};
	$start = '#!perl' unless $start =~ /^#!.*perl/;

	open my $in, '<', $opts{in} or croak "Can't open $opts{in}: $!";
	my @file = <$in>;
	close $in;

	foreach my $line ( @file ) {
		$linenum++;
		if ( $line =~ /^:endofperl\b/ ) {
			if (!exists $opts{update}) {
				warn "$opts{in} has already been converted to a batch file!\n";
				return;
			}
			$taildone++;
		}
		if ( not $linedone and $line =~ /^#!.*perl/ ) {
			if (exists $opts{update}) {
				$skiplines = $linenum - 1;
				$line .= '#line '.(1+$headlines)."\n";
			} else {
	$line .= '#line '.($linenum+$headlines)."\n";
			}
	$linedone++;
		}
		if ( $line =~ /^#\s*line\b/ and $linenum == 2 + $skiplines ) {
			$line = '';
		}
	}

	open my $out, '>', $opts{out} or croak "Can't open $opts{out}: $!";
	print $out $head;
	print $out $start, ( $opts{usewarnings} ? ' -w' : '' ),
						 "\n#line ", ($headlines+1), "\n" unless $linedone;
	print $out @file[$skiplines..$#file];
	print $out $tail unless $taildone;
	close $out;

	return $opts{out};
}

1;

# ABSTRACT: Windows specific helper bits

=begin Pod::Coverage

make_executable

=end Pod::Coverage

=cut
