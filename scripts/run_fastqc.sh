#!/bin/sh

# ------------------------------------------------------------------------------
# --- Analyze FASTQ file of reads with FASTQC
# ------------------------------------------------------------------------------

# Check that reads file was passed as parameter
USAGE="$0 reads.fq";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

READS_FQ=$1

echo "CMD: ${FASTQC}/fastqc -t 8 ${READS_FQ}";

${FASTQC}/fastqc -t 8 ${READS_FQ}

FQC_OUT_DIR=$(echo ${READS_FQ} | sed -e s"/\.fastq/_fastqc/")

# Move output files into reports directory and rename them
mv ${FQC_OUT_DIR} reports/

exit;
