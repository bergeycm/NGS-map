# -------------------------------------------------------------------------------------- #
# --- Makefile to run NGS-map pipeline. 
# --- Called by the executable shell script, indiv_analysis
# -------------------------------------------------------------------------------------- #

# Get user editable variables
include config.mk

GENOME_DIR=$(dir ${GENOME_FA})

# Output files of BWA index.
_BWA_INDEX_ENDINGS = .amb .ann .bwt .pac .sa
_PROTO_BWA_INDEX = $(addprefix ${GENOME_FA}, ${BWA_INDEX_ENDINGS})
_BWA_INDEX = $(subst .fa,,${PROTO_BWA_INDEX})

IND_ID_W_PE_SE = ${IND_ID}.${READ_TYPE}

# Steps. Can be called one-by-one with something like, make index_genome
# --- preliminary_steps
index_genome : ${GENOME_FA}i ${_BWA_INDEX}
make_dict : $(subst .fa,.dict,${GENOME_FA})
# --- pre_aln_analysis_steps:
ifeq ($(READ_TYPE),SE)
    fastqc : reports/${IND_ID}.readSE.stats.zip
else ifeq ($(READ_TYPE),PE)
    fastqc : $(addsuffix _fastqc/fastqc_report.html,$(subst data,reports,$(basename ${READ1} ${READ2})))
endif
# --- alignment_steps
ifeq ($(READ_TYPE),SE)
    align : results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam
else ifeq ($(READ_TYPE),PE)
    align : results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam
endif
sam2bam : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.sam.bam
sort_and_index_bam : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.sam.bam.sorted.bam.bai
get_alignment_stats : reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.txt
# --- post_alignment_filtering_steps
fix_mate_pairs : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.txt
filter_unmapped : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam.bai reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.txt
remove_dups : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam.bai reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.postdup.txt
add_read_groups : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.RG.bam
filter_bad_qual : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.txt
# --- snp_calling_steps
local_realign_targets : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.list
local_realign : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.realn.txt
call_snps : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.raw.bcf
filter_snps : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf
get_snp_stats : reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf.stats.txt
call_consensus : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.consensus.fq.gz
# --- archive_steps
compress_and_upload : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.tar.gz

# Group steps together
# --- Individual steps
preliminary_steps : index_genome make_dict
pre_aln_analysis_steps : fastqc
alignment_steps : align sam2bam sort_and_index_bam get_alignment_stats
post_alignment_filtering_steps : fix_mate_pairs filter_unmapped add_read_groups filter_bad_qual
snp_calling_steps : local_realign_targets local_realign call_snps filter_snps get_snp_stats call_consensus
archive_steps : compress_and_upload

# Steps for individuals
indiv : preliminary_steps pre_aln_analysis_steps alignment_steps post_alignment_filtering_steps snp_calling_steps archive_steps

# --- Inter-individual comparison steps
calc_coverage : results/DoC/DoC.${GENOME_NAME}.chr1.sample_summary
#merge_vcfs : results/${GENOME_NAME}.merged.flt.vcf
#get_merged_snp_stats : reports/${GENOME_NAME}.merged.flt.vcf.stats.txt
multi_sample_snp_call : ${GENOME_NAME}_snps/chr1.raw.snps.indels.vcf
multi_sample_snp_filter : ${GENOME_NAME}_snps/chr1.pass.snp.vcf
merge_multi_sample_snps : ${GENOME_NAME}.pass.snp.vcf.gz
vcf2ped : ${GENOME_NAME}.pass.snp.ped
binary_ped : ${GENOME_NAME}.pass.snp.bed
chrX_to_plink : ${GENOME_NAME}.chrX.pass.snp.bed
add_chrX : ${GENOME_NAME}.withX.pass.snp.bed
archive_multi_sample : results/multi-sample.bwa.${GENOME_NAME}.tar.gz

# Steps for inter-individual comparison
compare : calc_coverage multi_sample_snp_call multi_sample_snp_filter merge_multi_sample_snps vcf2ped binary_ped chrX_to_plink add_chrX archive_multi_sample

SHELL_EXPORT := 

# Export Make variables to child scripts
.EXPORT_ALL_VARIABLES :

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Preliminary Steps
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Index genome
# -------------------------------------------------------------------------------------- #

# The .fai output of samtools depends on the genome, BWA, samtools, & index_genome.sh
${GENOME_FA}i : ${GENOME_FA} #${BWA}/* ${SAMTOOLS}/* #scripts/index_genome.sh
	@echo "# === Indexing genome ========================================================= #";
	./scripts/index_genome.sh ${GENOME_FA};
	@sleep 2
	@touch ${GENOME_FA}i ${_BWA_INDEX}

# The output files of bwa depend on the output of samtools.
# A hack to deal with the problem make has with multiple targets dependent on one rule
# See for details:
# http://www.cmcrossroads.com/ask-mr-make/12908-rules-with-multiple-outputs-in-gnu-make
${_BWA_INDEX} : ${GENOME_FA}i

# -------------------------------------------------------------------------------------- #
# --- Make *.dict file
# -------------------------------------------------------------------------------------- #

# *.dict file depends on genome FASTA file
$(subst .fa,.dict,${GENOME_FA}) : ${GENOME_FA}
	@echo "# === Making *.dict file ====================================================== #";
	java -jar ${PICARD}/CreateSequenceDictionary.jar R=$< O=$@

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Analyze reads
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Analyze reads with FastQC. Total sequence bp, Maximum possible sequence depth
# -------------------------------------------------------------------------------------- #

# FastQC reports depend on read files, FastQC, and run_fastqc.sh
#$(addsuffix _fastqc/fastqc_report.html,$(subst data,reports,$(basename ${READ1}))) : ${READ1} ${FASTQC}/* scripts/run_fastqc.sh
#	@echo "# === Analyzing quality of reads (1st pair) before mapping ==================== #";
#	./scripts/run_fastqc.sh ${READ1}

reports/%_fastqc/fastqc_report.html : data/%.fastq ${FASTQC}/* scripts/run_fastqc.sh
	@echo "# === Analyzing quality of reads before mapping =============================== #";
	scripts/run_fastqc.sh $<
reports/${IND_ID}.readSE.stats.zip : ${READ_SE} ${FASTQC}/* #scripts/run_fastqc.sh
	@echo "# === Analyzing quality of reads (SE) before mapping ========================== #";
	./scripts/run_fastqc.sh ${READ_SE} ${IND_ID}.readSE.stats;

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Mapping to reference genomes
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Align reads to genome with BWA
# -------------------------------------------------------------------------------------- #

# Alignment output (*.sam) depends on bwa, the reads FASTAs, the genome (index), and align.sh
results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam : ${BWA}/* ${READ1} ${READ2} ${GENOME_FA}i #scripts/align.sh
	@echo "# === Aligning reads to genome ================================================ #";
	./scripts/align.sh ${GENOME_FA} ${GENOME_NAME};

# Align SE reads
# Alignment output (*.sam) depends on bwa, the reads FASTAs, the genome (index), and alignSE.sh
results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam : ${BWA}/* ${READ_SE} ${GENOME_FA}i #scripts/align.sh
	@echo "# === Aligning SE reads to genome ============================================= #";
	./scripts/alignSE.sh ${GENOME_FA} ${GENOME_NAME};

# -------------------------------------------------------------------------------------- #
# --- Convert SAM file to BAM file
# -------------------------------------------------------------------------------------- #

# BAM file depends on SAM file, samtools, genome .fai index, and scripts/sam2bam.sh
results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam : results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam ${SAMTOOLS}/* ${GENOME_FA}i #scripts/sam2bam.sh
	@echo "# === Converting SAM file to BAM file ========================================= #";
	./scripts/sam2bam.sh ${GENOME_FA}i results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam;

# Do same for SE
results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam.bam : results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam ${SAMTOOLS}/* ${GENOME_FA}i #scripts/sam2bam.sh
	@echo "# === Converting SAM file to BAM file ========================================= #";
	./scripts/sam2bam.sh ${GENOME_FA}i results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam;

# -------------------------------------------------------------------------------------- #
# --- Sort and index BAM
# -------------------------------------------------------------------------------------- #

# Sorted BAM file index depends on unsorted BAM file, scripts/sort_bam, and scripts/index_bam.sh
results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam.sorted.bam.bai : results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam #scripts/sort_bam scripts/index_bam.sh
	@echo "# === Sorting and Indexing PE BAM file ======================================== #";
	./scripts/sort_bam.sh results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam;
	./scripts/index_bam.sh results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam.sorted.bam;
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam
	sh ./scripts/zero_out_file.sh results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam.bam
	sh ./scripts/zero_out_file.sh ${READ1}
	sh ./scripts/zero_out_file.sh ${READ2}

# Sorted BAM file index depends on unsorted BAM file, scripts/sort_bam, and scripts/index_bam.sh
results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam.bam.sorted.bam.bai : results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam.bam #scripts/sort_bam scripts/index_bam.sh
	@echo "# === Sorting and Indexing SE BAM file ======================================== #";
	./scripts/sort_bam.sh results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam.bam;
	./scripts/index_bam.sh results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam.bam.sorted.bam;

# -------------------------------------------------------------------------------------- #
# --- Analyze alignment output with flagstat, idxstats, and stats
# -------------------------------------------------------------------------------------- #

# Align stats report depends on the sorted BAM and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.sam.bam.sorted.bam.bai #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output ============================================== #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.sam.bam.sorted.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.txt	

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Post-alignment filtering steps
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Fix mate pairs info (works for PE only, otherwise just copies BAM to new name)
# -------------------------------------------------------------------------------------- #

# BAM with fixed mate pair info depends on output BAM from sort_and_index.sh, Picard, and scripts/fix_mate_pairs.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.sam.bam.sorted.bam.bai ${PICARD}/* # scripts/fix_mate_pairs.sh
	@echo "# === Fixing mate pair info =================================================== #";
	./scripts/fix_mate_pairs.sh ${GENOME_NAME};

# Align stats report depends on the BAM with fixed mate pair info and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output (post mate pair fix) ========================= #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.txt;

# -------------------------------------------------------------------------------------- #
# --- Filtering for mapped (NOT for paired and properly paired)
# -------------------------------------------------------------------------------------- #

# Filtered BAM [index file] depends on output BAM from fix_mate_pairs.sh, BAMtools, and scripts/filter_mapped_reads_paired.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam.bai : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam ${BEDTOOLS}/* # scripts/filter_mapped_reads_paired.sh
	@echo "# === Filtering unmapped reads ================================================ #";
	./scripts/filter_mapped_reads_paired.sh ${GENOME_NAME};
	./scripts/index_bam.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam;
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.bam

# Align stats report depends on filtered BAM and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam.bai #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output (filtered for mapped) ======================== #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.txt;

# -------------------------------------------------------------------------------------- #
# --- Remove duplicates
# -------------------------------------------------------------------------------------- #

# BAM sans dups [index file] depends on output BAM from filtering, Picard, and scripts/remove_dups.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam.bai : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam.bai ${PICARD}/* # scripts/remove_dups.sh
	@echo "# === Removing duplicate reads mapped ========================================= #";
	./scripts/remove_dups.sh ${GENOME_NAME};
	./scripts/index_bam.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam;
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.bam

# Align stats report depends on BAM sans dups and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.postdup.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output (duplicates removed) ========================= #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.pairsfix.flt.postdup.txt;

# -------------------------------------------------------------------------------------- #
# --- Add read groups
# -------------------------------------------------------------------------------------- #

# BAM without RGs depends on output BAM, Picard, and scripts/add_read_groups.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.RG.bam : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam.bai ${PICARD}/* # scripts/add_read_groups.sh
	@echo "# === Adding read groups ====================================================== #";
	./scripts/add_read_groups.sh ${GENOME_NAME};
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.postdup.bam

# -------------------------------------------------------------------------------------- #
# --- Remove reads with low mapping quality
# -------------------------------------------------------------------------------------- #

# Filtered BAM depends on output BAM from add_read_groups.sh, BAMtools, and scripts/filter_mapped_reads_quality.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.RG.bam ${BEDTOOLS}/* # scripts/filter_mapped_reads_quality.sh
	@echo "# === Filtering low quality reads mapped to genome ============================ #";
	./scripts/filter_mapped_reads_quality.sh ${GENOME_NAME} ${MAPQUAL};
	./scripts/index_bam.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam;
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.RG.bam

# Align stats report depends on quality-filtered BAM and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output (after qual filtering) ======================= #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.txt;

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- SNP calling methods
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Local realignment, step 1: ID realign targets
# -------------------------------------------------------------------------------------- #

# List of intervals to realign depends on BAM of reads that passed filtering, GATK, and scripts/local_realign_get_targets.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.list : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai ${GATK}/* #scripts/local_realign.sh
	@echo "# === Identifying intervals in need or local realignment ====================== #";
	./scripts/local_realign_get_targets.sh ${GENOME_NAME} ${GENOME_FA};

# -------------------------------------------------------------------------------------- #
# --- Local realignment, step 2: realign around indels
# -------------------------------------------------------------------------------------- #

# Realigned BAM depends on list of realign targets, BAM of reads that passed filtering, GATK, and scripts/local_realign.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.list results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai ${GATK}/* #scripts/local_realign.sh
	@echo "# === Doing local realignment ================================================= #";
	./scripts/local_realign.sh ${GENOME_NAME} ${GENOME_FA};
	# Clear out intermediary files
	sh ./scripts/zero_out_file.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam

# Align stats report depends on realigned BAM and scripts/get_alignment_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.realn.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam #scripts/get_alignment_stats.sh
	@echo "# === Analyzing alignment output (locally realigned) ========================== #";
	./scripts/get_alignment_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.aln_stats.passed.realn.txt;

# -------------------------------------------------------------------------------------- #
# --- Call SNPs
# -------------------------------------------------------------------------------------- #

# Raw SNPs file depends on realigned BAM, VCFtools, BCFtools, and scripts/call_snps.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.raw.bcf : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${VCFTOOLS}/* ${BCFTOOLS}/* #scripts/call_snps.sh
	@echo "# === Calling raw SNPs relative to genome ===================================== #";
	./scripts/call_snps.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${GENOME_FA};

# -------------------------------------------------------------------------------------- #
# --- Filter SNPs for quality
# -------------------------------------------------------------------------------------- #

# Filtered SNP file depends on raw SNP file, BCFtools, and scripts/filter_snps.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.raw.bcf ${BCFTOOLS}/* #scripts/filter_snps.sh
	@echo "# === Filtering raw SNPs ====================================================== #";
	./scripts/filter_snps.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.raw.bcf;

# -------------------------------------------------------------------------------------- #
# --- Get basic stats on SNPs
# -------------------------------------------------------------------------------------- #

# File of SNP stats depends on VCF file, VCFtools, and scripts/get_snp_stats.sh
reports/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf.stats.txt : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf ${VCFTOOLS}/* #scripts/get_snp_stats.sh
	@echo "# === Getting basic SNPs stats ================================================ #";
	./scripts/get_snp_stats.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf;

# -------------------------------------------------------------------------------------- #
# --- Call consensus sequence
# -------------------------------------------------------------------------------------- #

# Consensus sequence depends on realigned BAM, SAMtools, BCFtools, and scripts/call_consensus.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.consensus.fq.gz : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${SAMTOOLS}/* ${BCFTOOLS}/* #scripts/call_consensus.sh
	@echo "# === Calling consensus sequence ============================================== #";
	./scripts/call_consensus.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${GENOME_FA} ${GENOME_NAME};

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Archiving steps
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Compress and optionally upload results files
# -------------------------------------------------------------------------------------- #

# Compressed archive depends on last results file
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.tar.gz : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.flt.vcf
	@echo "# === Compressing and optionally uploading results ============================ #";
	./scripts/compress_copy_results_s3.sh

# ====================================================================================== #
# ====================================================================================== #
# =====                                                                            ===== #
# ============= Summary steps to be run when all individuals are finished: ============= #
# =====                                                                            ===== #
# ====================================================================================== #
# ====================================================================================== #

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Coverage calculations
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Calculate coverage of targeted regions
# -------------------------------------------------------------------------------------- #

# PBS file to do this step, split by chromosome, exists. 
# Modify variables in script, then call with something like:
# 	qsub -t 1-21 pbs/gatk_DoC.pbs
# where 1-21 represents 20 chromosomes, plus X

# Last output file of coverage calculation depends on BAM files and GATK
results/DoC/DoC.${GENOME_NAME}.chr1.sample_summary : results/*.PE.bwa.${GENOME_NAME}.passed.realn.bam ${GATK}/*
	@echo "# === Calculating Depth of Coverage =========================================== #";
	./scripts/gatk_DoC_serial.sh

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Merge and summarize individually-called SNPs - Currently skipped
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Merge VCF files from individual SNP calling - Currently skipped
# -------------------------------------------------------------------------------------- #

# Merged VCF depends on individual VCFs, VCFtools, and scripts/merge_vcf.sh
results/${GENOME_NAME}.merged.flt.vcf : results/*.bwa.${GENOME_NAME}.passed.realn.flt.vcf ${VCFTOOLS}/* #scripts/merge_vcf.sh
	@echo "# === Merging individual VCF SNP files ======================================== #";
	./scripts/merge_vcf.sh;

# -------------------------------------------------------------------------------------- #
# --- Get stats on merged VCF - Currently skipped
# -------------------------------------------------------------------------------------- #

# File of SNP stats depends on VCF file, VCFtools, and scripts/get_snp_stats.sh
reports/${GENOME_NAME}.merged.flt.vcf.stats.txt : results/${GENOME_NAME}.merged.flt.vcf ${VCFTOOLS}/* #scripts/get_snp_stats.sh
	@echo "# === Getting basic SNPs stats ================================================ #";
	./scripts/get_snp_stats.sh results/${GENOME_NAME}.merged.flt.vcf;

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Multi-sample SNP calling and SNP filtration with GATK
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Perform multi-sample SNP-calling
# -------------------------------------------------------------------------------------- #

# PBS file to do this step, split by chromosome, exists. 
# Modify variables in script, then call with something like:
# 	qsub -t 1-21 pbs/call_gatk_genotyper.pbs
# where 1-21 represents 20 chromosomes, plus X

# Last raw SNP file depends on BAM files and GATK
${GENOME_NAME}_snps/chr1.raw.snps.indels.vcf : results/*.PE.bwa.${GENOME_NAME}.passed.realn.bam ${GATK}/*
	@echo "# === Performing multi-sample SNP calling ===================================== #";
	./scripts/call_gatk_genotyper_serial.sh

# -------------------------------------------------------------------------------------- #
# --- Filter variants for quality
# -------------------------------------------------------------------------------------- #

# PBS file to do this step, split by chromosome, exists. 
# Modify variables in script, then call with something like:
# 	qsub -t 1-20 pbs/filter_gatk_snps.pbs
# where 1-21 represents 20 chromosomes, plus X

# Last filtered SNP file depends on unfiltered SNP files and GATK
${GENOME_NAME}_snps/chr1.pass.snp.vcf : ${GENOME_NAME}_snps/chr*.raw.snps.indels.vcf ${GATK}/*
	@echo "# === Filtering multi-sample SNPs ============================================= #";
	./scripts/filter_gatk_snps_serial.sh

# -------------------------------------------------------------------------------------- #
# --- Merge SNP files together (autosomes only)
# -------------------------------------------------------------------------------------- #

# Merged SNP file depends on chromosomal filtered SNP files
${GENOME_NAME}.pass.snp.vcf.gz : ${GENOME_NAME}_snps/*.pass.snp.vcf
	@echo "# === Merging multi-sample SNPs (autosomes only) ============================== #";
	${VCFTOOLS}/vcf-concat ${GENOME_NAME}_snps/chr[0-9]*.pass.snp.vcf | gzip -c > ${GENOME_NAME}.pass.snp.vcf.gz

# -------------------------------------------------------------------------------------- #
# --- Convert to plink's PED format. Also edit MAP file.
# -------------------------------------------------------------------------------------- #

# PED file depends merged SNP VCF file
${GENOME_NAME}.pass.snp.ped : ${GENOME_NAME}.pass.snp.vcf.gz
	@echo "# === Converting VCF file to PED ============================================== #";
	${VCFTOOLS}/vcftools --gzvcf ${GENOME_NAME}.pass.snp.vcf.gz --plink --out ${GENOME_NAME}.pass.snp;
	# Edit the MAP file (${GENOME_NAME}.pass.snp.map) and get rid of the "chr"
	# VCF uses, e.g., "chr10" whereas plink wants just "10"
	sed -i -e 's/^chr//' ${GENOME_NAME}.pass.snp.map

# -------------------------------------------------------------------------------------- #
# --- Convert the PED to a binary PED file, and make FAM files, etc.
# -------------------------------------------------------------------------------------- #

# Binary PED file depends on PED file
${GENOME_NAME}.pass.snp.bed : ${GENOME_NAME}.pass.snp.ped
	@echo "# === Making binary PED file ================================================== #";
	${PLINK}/plink --noweb --file ${GENOME_NAME}.pass.snp --make-bed --out ${GENOME_NAME}.pass.snp

# -------------------------------------------------------------------------------------- #
# --- Create PED file and binary PED file of just chrX
# -------------------------------------------------------------------------------------- #

# Chromosome X binary PED file depends on chrX VCF file
${GENOME_NAME}.chrX.pass.snp.bed : ${GENOME_NAME}_snps/chrX.pass.snp.vcf
	@echo "# === Converting chrX VCF file to PED and binary PED ========================== #";
	${VCFTOOLS}/vcftools --vcf ${GENOME_NAME}_snps/chrX.pass.snp.vcf --plink --out ${GENOME_NAME}.chrX.pass.snp;
	# Edit the MAP file (${GENOME_NAME}.chrX.pass.snp.map) and get rid of the "chr"
	# VCF uses, e.g., "chrX" whereas plink wants just "X"
	sed -i -e 's/^chr//' ${GENOME_NAME}.chrX.pass.snp.map
	# Now convert PED to binary PED
	${PLINK}/plink --noweb --file ${GENOME_NAME}.chrX.pass.snp --make-bed --out ${GENOME_NAME}.chrX.pass.snp

# -------------------------------------------------------------------------------------- #
# --- Merge autosomes and chrX to create dataset of autosomes + chrX (PED + BED formats)
# -------------------------------------------------------------------------------------- #

# Autosomes plus chrX binary PED file depends on chromosomal filtered SNP files
${GENOME_NAME}.withX.pass.snp.bed : ${GENOME_NAME}_snps/*.pass.snp.vcf
	@echo "# === Merging multi-sample SNPs (now with X) ================================== #";
	# Concatenate VCF files and convert right into PLINK format
	${VCFTOOLS}/vcf-concat ${GENOME_NAME}_snps/chr*.pass.snp.vcf | \
		${VCFTOOLS}/vcftools --vcf - --plink --out ${GENOME_NAME}.withX.pass.snp;
	# Edit the MAP file (${GENOME_NAME}.pass.snp.map) and get rid of the "chr"
	# VCF uses, e.g., "chr10" whereas plink wants just "10"
	sed -i -e 's/^chr//' ${GENOME_NAME}.withX.pass.snp.map
	# Convert to binary PLINK file
	${PLINK}/plink --noweb --file ${GENOME_NAME}.withX.pass.snp --make-bed --out ${GENOME_NAME}.withX.pass.snp

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Archiving steps - Multi-sample SNP calling results
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Compress and optionally upload results files for multi-sample SNP calling
# -------------------------------------------------------------------------------------- #

# Compressed archive depends on last results file
results/multi-sample.bwa.${GENOME_NAME}.tar.gz : ${GENOME_NAME}.withX.pass.snp.bed
	@echo "# === Compressing and optionally uploading (multi-sample) results ============= #";
	./scripts/compress_copy_results_s3_multi_sample.sh
