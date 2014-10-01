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
	
	java -Xmx2g -jar ${GATK}/GenomeAnalysisTK.jar \
		-R ${GENOME_FA} \
		-T VariantFiltration \
		-o ${GENOME_NAME}_snps/chr${CHROM}.flt.vcf \
		--variant ${GENOME_NAME}_snps/chr${CHROM}.raw.snps.indels.vcf \
		--filterExpression "QD < 2.0" \
		--filterName "QDfilter" \
		--filterExpression "MQ < 40.0" \
		--filterName "MQfilter" \
		--filterExpression "FS > 60.0" \
		--filterName "FSfilter" \
		--filterExpression "HaplotypeScore > 13.0" \
		--filterName "HAPSCfilter" \
		--filterExpression "MQRankSum < -12.5" \
		--filterName "MQRSfilter" \
		--filterExpression "ReadPosRankSum < -8.0" \
		--filterName "RPRSfilter" \
		--missingValuesInExpressionsShouldEvaluateAsFailing	
	
	# Select variants with "FILTER=PASS" and are SNPs:
	java -jar ${GATK}/GenomeAnalysisTK.jar \
		-T SelectVariants \
		-R ${GENOME_FA} \
		--variant ${GENOME_NAME}_snps/chr${CHROM}.flt.vcf \
		--select_expressions "vc.isNotFiltered() && vc.isSNP()" \
		-o ${GENOME_NAME}_snps/chr${CHROM}.pass.snp.vcf

	let CHROM_ITER=CHROM_ITER+1 

done;

exit;