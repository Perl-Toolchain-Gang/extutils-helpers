package ExtUtils::Helpers;
use strict;
use warnings;
use Exporter 5.57 'import';

our @EXPORT_OK = qw/build_script make_executable split_like_shell/;

sub _make_executable {
  # Perl's chmod() is mapped to useful things on various non-Unix
  # platforms, so we use it everywhere even though it looks
  # Unixish.

  foreach (@_) {
    my $current_mode = (stat $_)[2];
    chmod $current_mode | oct(111), $_;
  }
}

if ($^O ne 'MSWin32') {
	eval <<'EOF';
use Text::ParseWords 3.24 qw/shellwords/;
use ExtUtils::MakeMaker;

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
EOF
}
else {
	eval <<'EOF';
use Config;

sub make_executable {
  _make_executable(@_);

  foreach my $script (@_) {
    if (-T $script) {
      # Skip native batch script
      next if $script =~ /\.(bat|cmd)$/;
      my $out = eval { pl2bat(in => $script, update => 1) };
      if ($@) {
        warn "WARNING: Unable to convert file '$script' to an executable script:\n$@";
      } else {
        _make_executable($out);
      }
    }
  }
}

# This routine was copied almost verbatim from the 'pl2bat' utility
# distributed with perl. It requires too much voodoo with shell quoting
# differences and shortcomings between the various flavors of Windows
# to reliably shell out
sub pl2bat {
  my %opts = @_;

  # NOTE: %0 is already enclosed in doublequotes by cmd.exe, as appropriate
  $opts{ntargs}    = '-x -S %0 %*';
  $opts{otherargs} = '-x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9';

  $opts{stripsuffix} = qr/\\.plx?/ unless exists $opts{stripsuffix};

  unless (exists $opts{out}) {
    $opts{out} = $opts{in};
    $opts{out} =~ s/$opts{stripsuffix}$//i;
    $opts{out} .= '.bat' unless $opts{in} =~ /\.bat$/i or $opts{in} =~ /^-$/;
  }

  my $head = <<EOT;
    \@rem = '--*-Perl-*--
    \@echo off
    if "%OS%" == "Windows_NT" goto WinNT
    perl $opts{otherargs}
    goto endofperl
    :WinNT
    perl $opts{ntargs}
    if NOT "%COMSPEC%" == "%SystemRoot%\\system32\\cmd.exe" goto endofperl
    if %errorlevel% == 9009 echo You do not have Perl in your PATH.
    if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
    goto endofperl
    \@rem ';
EOT

  $head =~ s/^\s+//gm;
  my $headlines = 2 + ($head =~ tr/\n/\n/);
  my $tail = "\n__END__\n:endofperl\n";

  my $linedone  = 0;
  my $taildone  = 0;
  my $linenum   = 0;
  my $skiplines = 0;

  my $start = $Config{startperl};
  $start = "#!perl" unless $start =~ /^#!.*perl/;

  open my $in, '<', $opts{in} or die "Can't open $opts{in}: $!";
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
        $line .= "#line ".(1+$headlines)."\n";
      } else {
	$line .= "#line ".($linenum+$headlines)."\n";
      }
	$linedone++;
    }
    if ( $line =~ /^#\s*line\b/ and $linenum == 2 + $skiplines ) {
      $line = "";
    }
  }

  open my $out, '>', $opts{out} or die or die "Can't open $opts{out}: $!";
  print $out $head;
  print $out $start, ( $opts{usewarnings} ? " -w" : "" ),
             "\n#line ", ($headlines+1), "\n" unless $linedone;
  print $out @file[$skiplines..$#file];
  print $out $tail unless $taildone;
  close $out;

  return $opts{out};
}

sub split_like_shell {
  # As it turns out, Windows command-parsing is very different from
  # Unix command-parsing.  Double-quotes mean different things,
  # backslashes don't necessarily mean escapes, and so on.  So we
  # can't use Text::ParseWords::shellwords() to break a command string
  # into words.  The algorithm below was bashed out by Randy and Ken
  # (mostly Randy), and there are a lot of regression tests, so we
  # should feel free to adjust if desired.

  local ($_) = @_;

  my @argv;
  return @argv unless defined && length;

  my $arg = '';
  my( $i, $quote_mode ) = ( 0, 0 );

  while ( $i < length() ) {

    my $ch      = substr( $_, $i  , 1 );
    my $next_ch = substr( $_, $i+1, 1 );

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
	      ( $i + 2 == length()  ||
		substr( $_, $i + 2, 1 ) eq ' ' )
	    ) { # for cases like: a"" => [ 'a' ]
      push( @argv, $arg );
      $arg = '';
      $i += 2;
    } elsif ( $ch eq '"' ) {
      $quote_mode = !$quote_mode;
    } elsif ( $ch eq ' ' && !$quote_mode ) {
      push( @argv, $arg ) if $arg;
      $arg = '';
      ++$i while substr( $_, $i + 1, 1 ) eq ' ';
    } else {
      $arg .= $ch;
    }

    $i++;
  }

  push( @argv, $arg ) if defined( $arg ) && length( $arg );
  return @argv;
}
EOF
}

sub build_script {
	return $^O eq 'VMS' ? 'Build.com' : 'Build';
}

# ABSTRACT: Various portability utilities for module builders
1;

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

=func split_like_shell

This function splits a string the same way as the local platform does.
