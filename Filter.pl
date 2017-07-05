#!/usr/bin/perl -w
use strict;
my ($infile,$outfile,$unique_read,$VAF) = @ARGV;
=head1 Usage

        perl Filter.pl  <infile> <outfile> <unique_read> <VAF>

=head1 Arguments

        <infile>        MrBam annotation result
        <outfile>       Filter result
	<unique_read>	Unique read support
	<VAF>		Variant allele frequency

=cut

die `pod2text $0` if (@ARGV != 4);

open FL,"$infile";
open OUT,">$outfile";
my $title = <FL>;
print OUT "$title";
while(<FL>){
	chomp;
	my @arr = split/\t/;
	my @crr = split/:/,$arr[-1];
	my @brr = split/,/,$crr[-1];
	my $read_support = $brr[-1] + $brr[-2] + $brr[-3] + $brr[-4] + $brr[-5] + $brr[-6];
	$crr[5] =~ s/%//;
	next if($read_support < $unique_read);
	next if($crr[5] < $VAF);
	print OUT "$_\n";
}
close FL;
close OUT;
