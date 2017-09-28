#!/bin/sh

# ------------------------------------------------------------------------------
# --- Align reads to genome with BWA mem
# ------------------------------------------------------------------------------

# Check that genome FASTA, and genome code were passed as parameters
USAGE="$0 genome.fasta genome_code [mem|aln]";
if [ -z "$3" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

# Strip ending from $1 (fasta)
GENOME_PATH=$(echo $1 | sed 's/.[^.]*$//g')
GENOME_CODE=$2
MEM_OR_ALN=$3

if [[ "$MEM_OR_ALN" == "mem" ]]; then

    bwa mem \
        $BWA_ALN_PARAM \
        $GENOME_PATH \
        $READ1 $READ2 > results/${IND_ID}.PE.bwa.${GENOME_CODE}.sam

else

    SAI_R1=results/${IND_ID}.PE.bwa.${GENOME_CODE}.R1.sai
    SAI_R2=results/${IND_ID}.PE.bwa.${GENOME_CODE}.R2.sai

    bwa aln \
        $BWA_ALN_PARAM \
        $GENOME_PATH \
        $READ1 > $SAI_R1

    bwa aln \
        $BWA_ALN_PARAM \
        $GENOME_PATH \
        $READ2 > $SAI_R2

    bwa sampe \
        $GENOME_PATH \
        $SAI_R1 $SAI_R2 \
        $READ1 $READ2 > results/${IND_ID}.PE.bwa.${GENOME_CODE}.sam
fi

exit;
