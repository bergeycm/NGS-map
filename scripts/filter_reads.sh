#!/bin/sh

# ------------------------------------------------------------------------------
# --- Filter reads
# ------------------------------------------------------------------------------

# Check that reads file was passed as parameter
USAGE="$0 reads.fq";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

FQ=$1

echo "${FASTX}/fastq_quality_filter \
	-i ${FQ} \
	-o ${FQ}.filtered.fastq \
	${FASTX_PARAM}";

${FASTX}/fastq_quality_filter \
	-i ${FQ} \
	-o ${FQ}.filtered.fastq \
	${FASTX_PARAM};

exit;