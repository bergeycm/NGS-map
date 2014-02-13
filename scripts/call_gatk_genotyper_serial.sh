#!/bin/bash

# ==============================================================================
# --- NOTE: It's a better idea to use the PBS version of this script,
# --- found at pbs/gatk_DoC.pbs. This really exists to have something
# --- to call from the Makefile, for users committed to that route.
# ==============================================================================

module load jdk/1.7.0

CHROM_ITER=1

while [ $CHROM_ITER -lt 22 ]; do

	if [ "$CHROM_ITER" -eq 21 ]; then
		CHROM=X
	else
		CHROM=$CHROM_ITER
	fi
	
	BAMS=(`ls results/*.PE.bwa.${GENOME_NAME}.passed.realn.bam`)
	
	count=0
	for b in ${BAMS[*]}; do
		BAMS[$count]="-I "$b" "
		count=`expr $count + 1`
	done
	
	# Make output directory
	mkdir ${GENOME_NAME}_snps
	
	java -jar ${GATK}/GenomeAnalysisTK.jar \
		-T UnifiedGenotyper \
		-R ${GENOME_FA} \
		${BAMS[*]} \
		-stand_call_conf 50.0 \
		-stand_emit_conf 10.0 \
		-o ${GENOME_NAME}_snps/chr${CHROM}.raw.snps.indels.vcf \
		-nct 4 \
		-nt 8 \
		-L chr${CHROM}

	let CHROM_ITER=CHROM_ITER+1 

done;

exit;

