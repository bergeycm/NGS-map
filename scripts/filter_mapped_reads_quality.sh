#!/bin/sh

# ------------------------------------------------------------------------------
# --- Filter mapped reads for quality
# ------------------------------------------------------------------------------

# Check that genome code and mapping quality were passed as parameter
USAGE="$0 genome_code map_quality";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1
MAPQUAL=$2

bamtools filter \
	-mapQuality ">=${MAPQUAL}" \
	-in results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.RG.bam \
	-out results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.passed.bam

exit;