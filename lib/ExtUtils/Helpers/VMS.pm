package ExtUtils::Helpers::VMS;
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/make_executable/;

use File::Copy qw/copy/;

sub make_executable {
	my $filename = shift;
	my $batchname = "$filename.com";
	copy($filename, $batchname);
	ExtUtils::Helpers::Unix::make_executable($batchname);
	return;
}

# ABSTRACT: VMS specific helper bits

__END__

=begin Pod::Coverage

make_executable

=end Pod::Coverage

=cut
