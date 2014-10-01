#!/bin/sh

# ========================================================================================
# --- Script to back-up results from multi-sample SNP calling on s3
# ========================================================================================

# ----------------------------------------------------------------------------------------
# --- Compress important files
# ----------------------------------------------------------------------------------------

# Figure out name for results archive

ARCHIVE=results/multi-sample.bwa.${GENOME_NAME}.tar.gz

# Copy log files and results to compressed tar ball

tar czf $ARCHIVE multi_sample_results*.log \
	${GENOME_NAME}.pass.snp.* \
	${GENOME_NAME}.chrX.pass.snp.* \
	${GENOME_NAME}.withX.pass.snp.*

# ----------------------------------------------------------------------------------------
# --- Upload to AWS S3 bucket
# ----------------------------------------------------------------------------------------

if [ $DO_S3_UPLOAD == TRUE ]; then

    echo "Uploading multi-sample results to Amazon S3..."
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
