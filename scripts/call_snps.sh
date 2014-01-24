#!/bin/sh

# ------------------------------------------------------------------------------
# --- Call SNPs with samtools mpileup
# ------------------------------------------------------------------------------

# Check that input BAM and genome were passed as parameters
USAGE="$0 input.bam genome.fa";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BAM=$1
OUT_BCF=$(echo $IN_BAM | sed 's/\.bam$/.raw.bcf/')
GENOME_FA=$2

echo "${SAMTOOLS}/samtools mpileup \
	-C50 \
	-Auf ${GENOME_FA} \
	${IN_BAM}  | \
	${BCFTOOLS}/bcftools view -bvcg - \
	> ${OUT_BCF}";

${SAMTOOLS}/samtools mpileup \
	-C50 \
	-Auf ${GENOME_FA} \
	${IN_BAM}  | \
	${BCFTOOLS}/bcftools view -bvcg - \
	> ${OUT_BCF}

exit;

