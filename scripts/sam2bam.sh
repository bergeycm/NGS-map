#!/bin/sh

# ------------------------------------------------------------------------------
# --- Convert SAM to BAM
# ------------------------------------------------------------------------------

# Check that genome FASTA and input SAM were passed as parameters
USAGE="$0 genome.index.fai in.sam";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

INDEX_FAI=$1
IN_SAM=$2

echo "samtools view \
	-b \
	-t ${INDEX_FAI} \
	-o ${IN_SAM}.bam \
	$IN_SAM";

samtools view \
	-b \
	-t ${INDEX_FAI} \
	-o ${IN_SAM}.bam \
	$IN_SAM

exit;