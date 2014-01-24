#!/bin/sh

# ------------------------------------------------------------------------------
# --- Get SNP stats
# ------------------------------------------------------------------------------

# Check that input VCF was passed as parameter
USAGE="$0 in.vcf";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_VCF=$1
OUT_FILE=$(echo $IN_VCF | sed -e 's/^results/reports/')

echo "${VCFTOOLS}/vcf-stats $IN_VCF > ${OUT_FILE}.stats.txt";

${VCFTOOLS}/vcf-stats $IN_VCF > ${OUT_FILE}.stats.txt


exit;

