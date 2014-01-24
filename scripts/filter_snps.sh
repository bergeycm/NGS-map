#!/bin/sh

# ------------------------------------------------------------------------------
# --- Filter SNPs for quality
# ------------------------------------------------------------------------------

# Check that input raw BCF was passed as parameter
USAGE="$0 raw_snps.bcf";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BCF=$1
OUT_VCF=$(echo $IN_BCF | sed 's/\.raw\.bcf/.flt.vcf/')

echo "${BCFTOOLS}/bcftools view ${IN_BCF} | \
	${BCFTOOLS}/vcfutils.pl varFilter -d ${SNP_MIN_COV} -D ${SNP_MAX_COV} \
	> ${OUT_VCF};";

${BCFTOOLS}/bcftools view ${IN_BCF} | \
	${BCFTOOLS}/vcfutils.pl varFilter -d ${SNP_MIN_COV} -D ${SNP_MAX_COV} \
	> ${OUT_VCF};

# While we're here, make indexed *.vcf.gz files

export PATH=$PATH:$TABIX

bgzip -c ${OUT_VCF} > ${OUT_VCF}.gz
tabix -p vcf ${OUT_VCF}.gz

exit;

