# -------------------------------------------------------------------------------------- #
# --- Makefile to run RADseq pipeline. 
# --- Called by the executable shell script, full_analysis
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
# --- pre_aln_analysis_steps:
ifeq ($(READ_TYPE),SE)
    fastqc : reports/${IND_ID}.readSE.stats.zip
else ifeq ($(READ_TYPE),PE)
    fastqc : reports/${IND_ID}.read1.stats.zip reports/${IND_ID}.read2.stats.zip
endif
# --- alignment_steps
ifeq ($(READ_TYPE),SE)
    align : results/${IND_ID}.readSE.bwa.${GENOME_NAME}.sai
    sampe_or_samse : results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam
else ifeq ($(READ_TYPE),PE)
    align : results/${IND_ID}.read1.bwa.${GENOME_NAME}.sai
    sampe_or_samse : results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam
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
#call_consensus : results/${IND_ID}.bwa.${GENOME_NAME}.consensus.fq.gz

# Group steps together
preliminary_steps : index_genome
pre_aln_analysis_steps : fastqc
alignment_steps : align sampe_or_samse sam2bam sort_and_index_bam get_alignment_stats
post_alignment_filtering_steps : fix_mate_pairs filter_unmapped add_read_groups filter_bad_qual
snp_calling_steps : local_realign_targets local_realign call_snps filter_snps get_snp_stats #call_consensus
# ---
merge_vcfs : results/merged.flt.vcf
get_merged_snp_stats : reports/merged.flt.vcf.stats.txt
make_re_bed : reports/${GENOME_CODE}_${ENZYME}_RADtags.bed
get_rad_counts : reports/${GENOME_CODE}_${ENZYME}_RAD_coverage.txt
analyze_rad_cov : reports/${GENOME_CODE}_${ENZYME}_RAD_summary.txt

# Steps for individuals
indiv : preliminary_steps pre_aln_analysis_steps alignment_steps post_alignment_filtering_steps snp_calling_steps 

# Steps for group
compare : merge_vcfs get_merged_snp_stats make_re_bed get_rad_counts analyze_rad_cov

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

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Analyze reads
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Analyze reads with FastQC. Total sequence bp, Maximum possible sequence depth
# -------------------------------------------------------------------------------------- #

# FastQC reports depend on read files, FastQC, and run_fastqc.sh
reports/${IND_ID}.read1.stats.zip : ${READ1} ${FASTQC}/* #scripts/run_fastqc.sh
	@echo "# === Analyzing quality of reads (1st pair) before mapping ==================== #";
	./scripts/run_fastqc.sh ${READ1} ${IND_ID}.read1.stats;
reports/${IND_ID}.read2.stats.zip : ${READ2} ${FASTQC}/* #scripts/run_fastqc.sh
	@echo "# === Analyzing quality of reads (2nd pair) before mapping ==================== #";
	./scripts/run_fastqc.sh ${READ2} ${IND_ID}.read2.stats;
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

# Alignment output (*.sai) depends on bwa, the reads FASTAs, the genome (index), and align.sh
# Using the first read as a stand in for the both 
results/${IND_ID}.read1.bwa.${GENOME_NAME}.sai : ${BWA}/* ${READ1} ${READ2} ${GENOME_FA}i #scripts/align.sh
	@echo "# === Aligning reads to genome ================================================ #";
	./scripts/align.sh ${GENOME_FA} ${GENOME_NAME};

# Read 2 depends on read 1
ifeq ($(READ_TYPE),PE)
    results/${IND_ID}.read2.bwa.${GENOME_NAME}.sai : results/${IND_ID}.read1.bwa.${GENOME_NAME}.sai
endif

# Align SE reads
# Alignment output (*.sai) depends on bwa, the reads FASTAs, the genome (index), and alignSE.sh
results/${IND_ID}.readSE.bwa.${GENOME_NAME}.sai : ${BWA}/* ${READ_SE} ${GENOME_FA}i #scripts/align.sh
	@echo "# === Aligning SE reads to genome ============================================= #";
	./scripts/alignSE.sh ${GENOME_FA} ${GENOME_NAME};

# -------------------------------------------------------------------------------------- #
# --- Run sampe and samse to generate SAM files
# -------------------------------------------------------------------------------------- #

# sampe output (*.sam) depends on *.sai files and sampe.sh
# Using the first read as a stand in for the both
results/${IND_ID}.PE.bwa.${GENOME_NAME}.sam : results/${IND_ID}.read1.bwa.${GENOME_NAME}.sai #scripts/sampe.sh
	@echo "# === Making SAM file from PE reads =========================================== #";
	./scripts/sampe.sh ${GENOME_FA} ${GENOME_NAME};

# samse output (*.sam) depends on *.sai file and sampe.sh
results/${IND_ID}.SE.bwa.${GENOME_NAME}.sam : results/${IND_ID}.readSE.bwa.${GENOME_NAME}.sai #scripts/sampe.sh
	@echo "# === Making SAM file from SE reads =========================================== #";
	./scripts/samse.sh ${GENOME_FA} ${GENOME_NAME};

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

# -------------------------------------------------------------------------------------- #
# --- Remove reads with low mapping quality
# -------------------------------------------------------------------------------------- #

# Filtered BAM depends on output BAM from add_read_groups.sh, BAMtools, and scripts/filter_mapped_reads_quality.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam.bai : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.fixed.filtered.RG.bam ${BEDTOOLS}/* # scripts/filter_mapped_reads_quality.sh
	@echo "# === Filtering low quality reads mapped to genome ============================ #";
	./scripts/filter_mapped_reads_quality.sh ${GENOME_NAME} ${MAPQUAL};
	./scripts/index_bam.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.bam;

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
# --- Call consensus sequence - Currently turned off
# -------------------------------------------------------------------------------------- #

# Consensus sequence depends on realigned BAM, SAMtools, BCFtools, and scripts/call_consensus.sh
results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.consensus.fq.gz : results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${SAMTOOLS}/* ${BCFTOOLS}/* #scripts/call_consensus.sh
	@echo "# === Calling consensus sequence ============================================== #";
	./scripts/call_consensus.sh results/${IND_ID_W_PE_SE}.bwa.${GENOME_NAME}.passed.realn.bam ${GENOME_FA} ${GENOME_NAME};

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Summary steps to be run when all individuals are finished
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Merge VCF files from individual SNP calling
# -------------------------------------------------------------------------------------- #

# Merged VCF depends on individual VCFs, VCFtools, and scripts/merge_vcf.sh
results/merged.flt.vcf : results/*.bwa.${GENOME_NAME}.passed.realn.flt.vcf ${VCFTOOLS}/* #scripts/merge_vcf.sh
	@echo "# === Merging individual VCF SNP files ======================================== #";
	./scripts/merge_vcf.sh;

# -------------------------------------------------------------------------------------- #
# --- Get stats on merged VCF
# -------------------------------------------------------------------------------------- #

# File of SNP stats depends on VCF file, VCFtools, and scripts/get_snp_stats.sh
reports/merged.flt.vcf.stats.txt : results/merged.flt.vcf ${VCFTOOLS}/* #scripts/get_snp_stats.sh
	@echo "# === Getting basic SNPs stats ================================================ #";
	./scripts/get_snp_stats.sh results/merged.flt.vcf;

# -------------------------------------------------------------------------------------- #
# --- Find RE sites in genome and generate BED file of these
# -------------------------------------------------------------------------------------- #

# RAD tag BED depends on RE finder script, genome file, and scripts/make_RE_site_bed.sh
reports/${GENOME_CODE}_${ENZYME}_RADtags.bed : ${RE_FINDER} ${GENOME_FA}i #scripts/make_RE_site_bed.sh
	@echo "# === Making BED file of RE sites ============================================= #";
	./scripts/make_RE_site_bed.sh;
	
# -------------------------------------------------------------------------------------- #
# --- Figure out which RE sites have sequences associated with them
# -------------------------------------------------------------------------------------- #

# RAD coverage output file depends on BED file, results/*.passed.realn.bam, and scripts/count_restr_enz_reads.sh
reports/${GENOME_CODE}_${ENZYME}_RAD_coverage.txt : reports/${GENOME_CODE}_${ENZYME}_RADtags.bed results/*.bwa.${GENOME_NAME}.passed.realn.bam #scripts/count_restr_enz_reads.sh
	@echo "# === Counting RAD tags with reads ============================================ #";
	./scripts/count_restr_enz_reads.sh;

# -------------------------------------------------------------------------------------- #
# --- Summarize RAD coverage data
# -------------------------------------------------------------------------------------- #

# RAD coverage summary depends on RAD coverage file and scripts/analyze_RAD_coverage.R
reports/${GENOME_CODE}_${ENZYME}_RAD_summary.txt : reports/${GENOME_CODE}_${ENZYME}_RAD_coverage.txt #scripts/analyze_RAD_coverage.R
	@echo "# === Summarizing RAD tags coverage info ====================================== #";
	./scripts/analyze_RAD_coverage.R reports/papAnu2_PspXI_RAD_coverage.txt > reports/${GENOME_CODE}_${ENZYME}_RAD_summary.txt;

# ====================================================================================== #
# -------------------------------------------------------------------------------------- #
# --- Multi-sample SNP calling with GATK
# -------------------------------------------------------------------------------------- #
# ====================================================================================== #

# -------------------------------------------------------------------------------------- #
# --- Figure out how to partition GATK jobs (e.g. by chromosome)
# -------------------------------------------------------------------------------------- #

# Dummy text files depend on *.fai genome index
	# Make dummy text files, one per line in *.fai genome index

# -------------------------------------------------------------------------------------- #
# --- Call UnifiedGenotyper
# -------------------------------------------------------------------------------------- #

# *.raw.snps.indels.vcf depends on *.dummy.file 
	# UnifiedGenotyper as in call_gatk_genotyper.pbs

# -------------------------------------------------------------------------------------- #
# --- Filter variants for quality
# -------------------------------------------------------------------------------------- #

# chr${i}.flt.vcf depends on *.raw.snps.indels.vcf
	# VariantFiltration

# -------------------------------------------------------------------------------------- #
# --- Keep only SNPs that pass our controls
# -------------------------------------------------------------------------------------- #

# chr${i}.pass.snp.vcf depends on
	# SelectVariants
	# touch some marker file (SV_done_marker)

# -------------------------------------------------------------------------------------- #
# --- Merge SNP files together
# -------------------------------------------------------------------------------------- #

# big merged VCF depends on SV_done_marker
	# Merge (chromosomal) VCF files

# -------------------------------------------------------------------------------------- #
# --- Convert to plink's PED format
# -------------------------------------------------------------------------------------- #

# PED file depends on merged VCF
	# Convert to PED

# -------------------------------------------------------------------------------------- #
# --- Make binary PED file
# -------------------------------------------------------------------------------------- #

# Binary PED depends on PED file
	# Convert to binary PED
