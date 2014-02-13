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
	mkdir results/DoC

	java -Xmx2g -jar ${GATK}/GenomeAnalysisTK.jar \                                                                                                                       
		-R ${GENOME_FA} \                                                                                                                                             
		-T DepthOfCoverage \                                                                                                                                          
		-o results/DoC/DoC.${GENOME_NAME}.chr${CHROM} \                                                                                                           
		${BAMS[*]} \                                                                                                                                                  
		-L chr${CHROM} \                                                                                                                                              
		--omitDepthOutputAtEachBase \                                                                                                                                 
		-ct 5 -ct 10 -ct 20

	let CHROM_ITER=CHROM_ITER+1 

done;

exit;

