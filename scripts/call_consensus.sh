#!/bin/sh

# ------------------------------------------------------------------------------
# --- Call consensus sequence
# ------------------------------------------------------------------------------

# Check that input BAM, genome FASTA, and genome name were passed as parameters
USAGE="$0 input.bam genome.fa genome_name";
if [ -z "$3" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BAM=$1
GENOME_FA=$2
GENOME_NAME=$3

echo "${SAMTOOLS}/samtools mpileup \
	-uf ${GENOME_FA} \
	${IN_BAM} | \
	${BCFTOOLS}/bcftools view -c - | \
	${BCFTOOLS}/vcfutils.pl vcf2fq -d ${SNP_MIN_COV} -D ${SNP_MAX_COV} | \
	gzip > results/${IND_ID}.bwa.${GENOME_NAME}.consensus.fq.gz";

# -d = minimum read depth
# -D = maximum read depth
# -d should be one third of avg depth
# -D should be twice avg depth

${SAMTOOLS}/samtools mpileup \
	-uf ${GENOME_FA} \
	${IN_BAM} | \
	${BCFTOOLS}/bcftools view -c - | \
	${BCFTOOLS}/vcfutils.pl vcf2fq -d ${SNP_MIN_COV} -D ${SNP_MAX_COV} | \
	gzip > results/${IND_ID}.bwa.${GENOME_NAME}.consensus.fq.gz;

exit;

