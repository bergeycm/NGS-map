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
# or in gzip'd FASTQ format and end in '.fastq.gz'
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

FASTQC=~/bin/FastQC
FASTX=~/bin/fastx
BWA=~/bin/bwa-0.6.2
SAMTOOLS=~/bin/samtools
BEDTOOLS=~/bin/BEDTools-Version-2.13.4/bin
LIFTOVER=~/bin/liftover
PICARD=~/bin/picard-tools-1.77
BAMTOOLS=~/bin/bamtools/bin
GATK=~/bin/GATK
BCFTOOLS=~/bin/samtools/bcftools
VCFTOOLS=~/bin/vcftools_0.1.9/bin
TABIX=~/bin/tabix-0.2.6
PLINK=~/bin/plink-1.07-x86_64

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
# Max number of file handles to keep open when Picard's MarkDuplicates writes to disk.
# This should be a bit lower than the per-process max number of files that can be open.
# You can find that max using command 'ulimit -n'
# This avoids the "java.io.FileNotFoundException: (Too many open files)" exception
PICARD_MARK_DUP_MAX_FILES=4000

# -------------------------------------------------------------------------------------- #
# --- Parameters for multi-sample SNP calling
# -------------------------------------------------------------------------------------- #

