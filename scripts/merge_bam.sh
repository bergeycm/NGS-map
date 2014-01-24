#!/bin/sh

# ------------------------------------------------------------------------------
# --- Merge BAM files from SE and PE runs
# ------------------------------------------------------------------------------

# Check that genome code was passed as parameter
USAGE="$0 genome_code";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1

echo "$SAMTOOLS/samtools merge \
	results/${IND_ID}_MERGED.bwa.${GENOME_CODE}.sam.bam.sorted.bam \
	results/${IND_ID}.bwa.${GENOME_CODE}.sam.bam.sorted.bam \
	results/${IND_ID}.SE.bwa.${GENOME_CODE}.sam.bam.sorted.bam";

$SAMTOOLS/samtools merge \
	results/${IND_ID}_MERGED.bwa.${GENOME_CODE}.sam.bam.sorted.bam \
	results/${IND_ID}.bwa.${GENOME_CODE}.sam.bam.sorted.bam \
	results/${IND_ID}.SE.bwa.${GENOME_CODE}.sam.bam.sorted.bam

exit;