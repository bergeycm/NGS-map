#!/bin/sh

# ------------------------------------------------------------------------------
# --- Run samse to generate SAM file
# ------------------------------------------------------------------------------

# Check that genome FASTA and genome code were passed as parameters
USAGE="$0 genome.fasta genome_code";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

# Strip ending from $1 (fasta)
GENOME_PATH=$(echo $1 | sed 's/.[^.]*$//g')

GENOME_CODE=$2

$BWA/bwa samse \
	$GENOME_PATH \
	results/${IND_ID}.readSE.bwa.${GENOME_CODE}.sai \
	$READ_SE \
	> results/${IND_ID}.SE.bwa.${GENOME_CODE}.sam

exit;