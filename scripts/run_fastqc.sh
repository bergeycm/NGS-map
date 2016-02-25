#!/bin/sh

# ------------------------------------------------------------------------------
# --- Analyze FASTQ file of reads with FASTQC
# ------------------------------------------------------------------------------

# Check that reads file and output directory name were passed as parameters
USAGE="$0 reads.fq";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

READS_FQ=$1

echo "CMD: ${FASTQC}/fastqc -t 8 ${READS_FQ}";

${FASTQC}/fastqc -t 8 ${READS_FQ}

FQC_OUT_PRE=$(echo ${READS_FQ} | sed -e s"/\.fastq\.gz/_fastqc/")

# Move output files into reports directory and rename them
mv ${FQC_OUT_PRE}.html reports/
mv ${FQC_OUT_PRE}.zip  reports/

exit;
