#!/bin/sh

# ------------------------------------------------------------------------------
# --- Remove Duplicates
# ------------------------------------------------------------------------------

# Check that genome code was passed as parameter
USAGE="$0 genome_code";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1

# Remove duplicates with Picard, if user instructs

if [ "$MARK_DUPS" = "TRUE" ]; then

	# Make temp folder
	TMP_DIR=tmp/$RANDOM
	mkdir -p $TMP_DIR

echo "CMD: java -Djava.io.tmpdir=${TMP_DIR} \
		-jar ${PICARD}/picard.jar MarkDuplicates \
		INPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.bam \
		OUTPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.postdup.bam \
		M=reports/duplicate_report.txt \
		VALIDATION_STRINGENCY=SILENT \
		REMOVE_DUPLICATES=false \
		MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=${PICARD_MARK_DUP_MAX_FILES}";

	java -Djava.io.tmpdir=${TMP_DIR} \
		-jar ${PICARD}/picard.jar MarkDuplicates \
		INPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.bam \
		OUTPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.postdup.bam \
		M=reports/duplicate_report.txt \
		VALIDATION_STRINGENCY=SILENT \
		REMOVE_DUPLICATES=false \
		MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=${PICARD_MARK_DUP_MAX_FILES}


	# Delete temp folder
	rm -r $TMP_DIR

elif [ "$MARK_DUPS" = "FALSE" ]; then

	# Otherwise just copy input file to output
	echo "Duplicates NOT being removed, as instructed by user."
	cp results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.bam results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.postdup.bam
	cp results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.bam.bai results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.filtered.postdup.bam.bai
	
else

	echo "ERROR: MARK_DUPS must be equal to either TRUE or FALSE. Correct error in config.mk." 1>&2 ;
	exit 1;
	
fi

exit;
