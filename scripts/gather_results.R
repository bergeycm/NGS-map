#!/usr/bin/env Rscript 

# ========================================================================================
# === Program to gather data after runs ==================================================
# ========================================================================================

final.bams = Sys.glob("results/*.passed.realn.bam")
inds = gsub("results/([^\\.]+).*", "\\1", final.bams, perl=TRUE)

# ----------------------------------------------------------------------------------------
# --- Reads per individual: --------------------------------------------------------------
# ----------------------------------------------------------------------------------------

cat ("# --- READS: Reads per individual: ---------------------------------------------\n")

total_raw_reads = 0;

for(i in 1:length(inds)) {
	cmd.reads = paste (	"grep 'Total reads:' reports/", inds[i], 
						".*.bwa.*.aln_stats.txt | sed 's/[^0-9]//g'", sep="");
	
	reads = as.numeric(system(cmd.reads, intern=TRUE));
	
	# Keep track of all reads from all individuals
	total_raw_reads = total_raw_reads + reads
	
	cat (paste(inds[i], " - individual raw reads:\t", reads, "\n", sep=""));
}

# ----------------------------------------------------------------------------------------
# --- Total sequenced reads in all samples -----------------------------------------------
# ----------------------------------------------------------------------------------------

cat ("# --- Total sequenced reads in all samples -------------------------------------\n")

cat (paste(total_raw_reads, "\n"))

# ----------------------------------------------------------------------------------------
# --- Mapped reads per individual: -------------------------------------------------------
# ----------------------------------------------------------------------------------------

cat ("# --- Mapped reads per individual: ---------------------------------------------\n")

total_raw_reads = 0;

for(i in 1:length(inds)) {

	cmd.mapped = paste(	"grep 'Mapped reads:' reports/", inds[i],
						".*.bwa.*.aln_stats.txt | sed 's/[^[0-9\\.\\%\\(\\)]//g' ",
						"| sed 's/(/ (/g'", sep="");
	
	mapped = system(cmd.mapped, intern=TRUE);
	
	cat (paste(inds[i], " - mapped reads:\t", mapped, "\n", sep=""));
}

# ----------------------------------------------------------------------------------------
# --- Mapped reads passing QC: -----------------------------------------------------------
# ----------------------------------------------------------------------------------------

cat ("# --- Mapped reads passing QC: -------------------------------------------------\n")

total_raw_reads = 0;

for(i in 1:length(inds)) {
	cmd.passed = paste ("grep 'Total reads:' reports/", inds[i], 
						".*.bwa.*.aln_stats.passed.realn.txt ",
						"| sed 's/[^0-9]//g'", sep="");
	
	passed = as.numeric(system(cmd.passed, intern=TRUE));
	
	cat (paste(inds[i], " - passing reads:\t", passed, "\n", sep=""));
}

