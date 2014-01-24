#!/bin/sh

# ------------------------------------------------------------------------------
# --- Compare SNPs between individuals
# ------------------------------------------------------------------------------

TABIX=/home/cmb433/exome_macaque/bin/tabix-0.2.6
export PATH=$PATH:$TABIX
VCFTOOLS=/home/cmb433/exome_macaque/bin/vcftools_0.1.9/bin

all_files=

for vcf_file in results/*.vcf
do
	bgzip -c $vcf_file > ${vcf_file}.gz
	tabix -p vcf ${vcf_file}.gz
	all_files="$all_files $vcf_file.gz"
done

${VCFTOOLS}/vcf-compare ${all_files} > reports/snp_overlap_data.txt

exit;