#!/bin/sh

# ------------------------------------------------------------------------------
# --- Do local realignment around indels
# ------------------------------------------------------------------------------

# Check that genome code and genome were passed as parameters
USAGE="$0 genome_code genome.fa";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1
GENOME_FA=$2

# Make temp folder
TMP_DIR=tmp/$RANDOM
mkdir -p $TMP_DIR

java -Xmx4g -Djava.io.tmpdir=${TMP_DIR} \
	-jar ${GATK}/GenomeAnalysisTK.jar \
	-I results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.bam \
	-R ${GENOME_FA} \
	--filter_mismatching_base_and_quals \
	-T IndelRealigner \
	-targetIntervals results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.bam.list \
	-o results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.realn.bam

# Delete temp folder
rm -r $TMP_DIR

# Copy index file, since we expect it later with a slightly different name
cp results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.realn.bai results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.realn.bam.bai

exit;

