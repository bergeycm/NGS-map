#!/bin/sh

# ========================================================================================
# --- Script to gather up important results and transfer them to s3
# ========================================================================================

# ----------------------------------------------------------------------------------------
# --- Compress important files
# ----------------------------------------------------------------------------------------

# Figure out name for results archive

ARCHIVE=results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.tar.gz

# Copy log files, reports, and select results to compressed tar ball

tar czf $ARCHIVE *.log \
	reports/ \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bai \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam.bai \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.raw.bcf \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf.gz \
	results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf.gz.tbi

# ----------------------------------------------------------------------------------------
# --- Upload to AWS S3 bucket
# ----------------------------------------------------------------------------------------

if [ $DO_S3_UPLOAD == TRUE ]; then

    echo "Uploading results to Amazon S3..."
    echo " - Using bucket s3://$S3_PROJECT_BUCKET_NAME"

	# Make bucket
	aws s3 mb s3://$S3_PROJECT_BUCKET_NAME

	# Copy compressed archive to S3
	aws s3 cp $ARCHIVE s3://$S3_PROJECT_BUCKET_NAME

	echo "Finished uploading."
else
	echo "NOT uploading results to Amazon S3."
fi

exit
