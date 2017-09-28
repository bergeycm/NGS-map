#!/bin/sh

# ------------------------------------------------------------------------------
# --- Sort BAM
# ------------------------------------------------------------------------------

# Check that BAM file was passed as parameter
USAGE="$0 mapped_reads.bam";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BAM=$1

# Sort BAM
# Output file is *.sorted.bam

echo "CMD: samtools sort \
	$IN_BAM \
	-o $IN_BAM.sorted.bam\
        --threads 7";

samtools sort \
	$IN_BAM \
	-o $IN_BAM.sorted.bam \
        --threads 7

exit;