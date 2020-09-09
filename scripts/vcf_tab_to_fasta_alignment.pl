#!/usr/bin/perl

# ******************************************************************************************
# NOTE: Standalone version of this script is available at:
# https://github.com/bergeycm/vcf-tab-to-fasta/
# ******************************************************************************************

# Program to convert output of VCFtools' vcf-to-tab (modified to only export IUPAC SNPs)
# to FASTA alignment.

# Sample input file
#	$ head results/merged.flt.vcf.tab
#	chr10	94051	C	./	./	./	./	./	T/T
#	chr10	94056	T	./	./	./	./	./	C/C
#	chr10	94180	G	./	A/A	./	./	./	./


use strict;
use warnings;

my %iupac = (
			'G/G' => 'G',
			'C/C' => 'C',
			'T/T' => 'T',
			'A/A' => 'A',

			'G/T' => 'K',
			'T/G' => 'K',
			'A/C' => 'M',
			'C/A' => 'M',
			'C/G' => 'S',
			'G/C' => 'S',
			'A/G' => 'R',
			'G/A' => 'R',
			'A/T' => 'W',
			'T/A' => 'W',
			'C/T' => 'Y',
			'T/C' => 'Y',

			'./.' => '.',
		);

#my $input_tab = "results/merged.flt.vcf.tab";
my $input_tab = "results/stacks/batch_1.vcf.tab";

open (TAB, "<$input_tab")
	or die "ERROR: Could not open input file $input_tab.\n";

my $header = <TAB>;

my @col_names = split /\t/, $header;

# Make temporary file with just lines we're going to use
my $temp_tab = $input_tab . "_clean";
open (TEMP, ">$temp_tab")
	or die "ERROR: Could not open temp file $temp_tab.\n";

LINE: foreach my $line (<TAB>) {

	my @data = split /\t/, $line;
	
	# Skip if this is indel (Length of @data will be less than 8)
	if ((scalar @data) < 8) {
		next LINE;
	}
	
	# Skip if any basepairs are actually 2 or more together
	for (my $i = 2; $i < 8; $i++) {
		
		my $bp = $data[$i]; 
		chomp $bp;
		if ($bp =~ /\w{2,}/) {
			next LINE;
		}
	}
	
#		# Exclude heterozygotes. Keep only fixed SNPs
#		for (my $i = 2; $i < 8; $i++) {
#			
#			my $bp = $data[$i]; 
#			chomp $bp;
#			if ($bp =~ /(\w)\/(\w)/) {
#				if ($1 ne $2) {
#					next LINE;
#				}
#			}
#		}
#		
#		# Skip BPs with too much missing data
#		my $required = 5;
#	
#		for (my $i = 2; $i < 8; $i++) {
#	
#			my $missing_count = 0;		
#			my $bp = $data[$i]; 
#			chomp $bp;
#			if ($bp eq "./") {
#				$missing_count++
#			}
#			
#			if (6 - $missing_count < $required) {
#				next LINE;
#			}
#		}
	
	# Otherwise write line to pure temporary file
	print TEMP $line;
}
	
close TAB;
close TEMP;

# Now convert cleaned tabular file to FASTA alignment

for (my $i = 3; $i < 8; $i++) {

	my $ind = $col_names[$i];
	chomp $ind;
	
	print ">" . $ind . "\n";
	
	open (TEMP, "<$temp_tab")
		or die "ERROR: Could not open temp file $temp_tab.\n";

	# Count number of bp printed so far in this line
	my $count = 0;
	
	foreach my $line (<TEMP>) {
	
		my @data = split /\t/, $line;
		
		my $nuc = $data[$i];
		chomp $nuc;
		
		# Infer and print basepair. There are a few possibilities 
		
		# If we're reference, just print basepair
		if ($i == 2) {
			print $nuc;
			$count++;
		
		# Missing data
		} elsif ($nuc eq './' || $nuc eq './.') {
			print '-';
			$count++;
		
		# Data
		} elsif ($nuc =~ /(\w)\/(\w)/) {
			my $first = $1;
			my $second = $2;
			
			# Homozygote
			if ($first eq $second) {
				print $first;
				$count++;
			
			# Heterozygote
			} else {
				my $gt = $first . '/' . $second;
				if ( !exists($iupac{$gt}) ) { die "ERROR: BP is $nuc\n"; }
                $gt = $iupac{$gt};
				print $gt;
				$count++;
			}
		}
			
		if ($count == 100) {
			print "\n";
			$count = 0;
		}
	}
	
	close TEMP;
	
	print "\n";
}

exit;
