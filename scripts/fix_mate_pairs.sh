#!/bin/sh

# ------------------------------------------------------------------------------
# --- Fix Mate Pair Info
# ------------------------------------------------------------------------------

# Check that genome code was passed as parameter
USAGE="$0 genome_code";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

GENOME_CODE=$1

# Only fix mate pairs if this is a PE run

if [ "$READ_TYPE" = "PE" ]; then

	# Make temp folder
	TMP_DIR=tmp/$RANDOM
	mkdir -p $TMP_DIR

	# Then fix mate pair info with Picard:
	# Also shorten the filename
	java -Djava.io.tmpdir=${TMP_DIR} \
		-jar ${PICARD}/picard.jar FixMateInformation \
		INPUT= results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.sam.bam.sorted.bam \
		OUTPUT=results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.bam \
		SO=coordinate \
		VALIDATION_STRINGENCY=LENIENT \
		CREATE_INDEX=true
	
	# Delete temp folder
	rm -r $TMP_DIR

else 
	# Just copy the input to the "fixed.bam" 
	# if this is a SE run and we're not actually doing any mate pair fixing
	cp results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.sam.bam.sorted.bam results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.bam
	
	# Copy the bam index too
	cp results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.sam.bam.sorted.bam.bai results/${IND_ID_W_PE_SE}.bwa.${GENOME_CODE}.fixed.bam.bai
fi
	
exit;
