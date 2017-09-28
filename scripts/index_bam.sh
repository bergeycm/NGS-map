#!/bin/sh

# ------------------------------------------------------------------------------
# --- Index BAM
# ------------------------------------------------------------------------------

# Check that BAM file was passed as parameter
USAGE="$0 mapped_reads.bam";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BAM=$1

# Index BAM

echo "CMD: samtools index \
	$IN_BAM;";

samtools index \
	$IN_BAM $IN_BAM.bai;

exit;