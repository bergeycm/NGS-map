#!/usr/bin/perl

# Program to convert FASTA alignment output from vcf_tab_to_fasta_alignment.pl to
# NEXUS format.

use strict;
use warnings;

use lib '/home/cmb433/local_perl/';

use Bio::AlignIO;

my $in  = Bio::AlignIO->new(	-file   => "results/stacks/batch_1.align.fasta",
								-format => "fasta");
my $out = Bio::AlignIO->new(	-file => ">results/stacks/batch_1.align.nexus",
								-format => "nexus");
 
while (my $aln = $in->next_aln) { 
	$out->write_aln($aln); 
}