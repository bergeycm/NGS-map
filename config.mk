# -------------------------------------------------------------------------------------- #
# --- Configuration makefile of user-editable variables 
# -------------------------------------------------------------------------------------- #

# All paths must be absolute or relative to the NGS-map top directory

# -------------------------------------------------------------------------------------- #
# --- Paths to input files
# -------------------------------------------------------------------------------------- #

# Individual ID (used to name files)
IND_ID=P_trog

# Paths to input reads files
# Must be in FASTQ format and end in '.fastq'
# FastQC will not name the output file properly if ending is '.fq'
READ1=./data/${IND_ID}.read1.fastq
READ2=./data/${IND_ID}.read2.fastq
READ_SE=./data/${IND_ID}_SE.fastq

# Paired-end or single-end analysis?
# Must be either PE or SE
READ_TYPE=PE

# Paths to genomes files
# Must be in FASTA format
GENOME_FA=genomes/hg19/hg19.fa

# Figure out genome code from path to genome FASTA
GENOME_CODE=$(notdir $(basename $(GENOME_FA)))

# Common name of genome (used to name files)
GENOME_NAME=human

# -------------------------------------------------------------------------------------- #
# --- Paths to external programs
# -------------------------------------------------------------------------------------- #

FASTQC=/home/cmb433/exome_macaque/bin/FastQC
FASTX=/home/cmb433/exome_macaque/bin/fastx
BWA=/home/cmb433/exome_macaque/bin/bwa-0.6.2
SAMTOOLS=/home/cmb433/exome_macaque/bin/samtools
BEDTOOLS=/home/cmb433/exome_macaque/bin/BEDTools-Version-2.13.4/bin
LIFTOVER=/home/cmb433/exome_macaque/bin/liftover
PICARD=/home/cmb433/exome_macaque/bin/picard-tools-1.77
BAMTOOLS=/home/cmb433/exome_macaque/bin/bamtools/bin
GATK=/home/cmb433/exome_macaque/bin/GATK
BCFTOOLS=/home/cmb433/exome_macaque/bin/samtools/bcftools
VCFTOOLS=/home/cmb433/exome_macaque/bin/vcftools_0.1.9/bin
TABIX=/home/cmb433/exome_macaque/bin/tabix-0.2.6

# -------------------------------------------------------------------------------------- #
# --- Parameters for external programs
# -------------------------------------------------------------------------------------- #

# BWA parameters
BWA_ALN_PARAM=-t 8
# SAMtools mpileup parameters
SNP_MIN_COV=3
SNP_MAX_COV=100
# BAMtools filter parameters
MAPQUAL=20
# Should we mark duplicates? TRUE or FALSE
MARK_DUPS=TRUE

# -------------------------------------------------------------------------------------- #
# --- Parameters for multi-sample SNP calling
# -------------------------------------------------------------------------------------- #

