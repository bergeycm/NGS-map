#!/bin/sh

# ------------------------------------------------------------------------------
# --- Align reads to genome with BWA mem
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

$BWA/bwa mem \
	$BWA_ALN_PARAM \
	$GENOME_PATH \
	$READ1 $READ2 > results/${IND_ID}.PE.bwa.${GENOME_CODE}.sam

exit;
