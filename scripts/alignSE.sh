#!/bin/sh

# ------------------------------------------------------------------------------
# --- Align SE reads to genome with BWA. Then sneak them into PE BAM
# ------------------------------------------------------------------------------

# Check that genome FASTA, and genome code were passed as parameters
USAGE="$0 genome.fasta genome_code";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

# Strip ending from $1 (fasta)
GENOME_PATH=$(echo $1 | sed 's/.[^.]*$//g')
GENOME_CODE=$2

echo "CMD: $BWA/bwa aln \
	$BWA_ALN_PARAM \
	$GENOME_PATH \
	$READ_SE \
	> results/${IND_ID}.readSE.bwa.${GENOME_CODE}.sai;";

$BWA/bwa aln \
	$BWA_ALN_PARAM \
	$GENOME_PATH \
	$READ_SE \
	> results/${IND_ID}.readSE.bwa.${GENOME_CODE}.sai;

exit;