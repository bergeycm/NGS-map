#!/bin/sh

# ------------------------------------------------------------------------------
# --- Add Read Groups
# ------------------------------------------------------------------------------

# Check that genome code was passed as parameter
USAGE="$0 genome_code";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1

# Add read groups with Picard:

java -jar ${PICARD}/AddOrReplaceReadGroups.jar \
	INPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.postdup.bam \
	OUTPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.RG.bam \
	RGLB=${IND_ID_W_PE_SE} \
	RGPL=Illumina \
	RGPU=Group1 \
	RGSM=${IND_ID_W_PE_SE}

exit;