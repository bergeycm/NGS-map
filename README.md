NGS-map
=======

A general pipeline for mapping next-gen sequencing reads and calling variants

## Quick Start Instructions

Here's the rough outline of how to use these scripts to do a simple mapping analysis. The mapping analysis uses BWA, and the variant calling uses GATK.

* Put uncompressed FASTQ file in folder `data/`
    - Demultiplex reads with `scripts/demultiplex.sh` and/or `scripts/demultiplex_SE.sh`
* For each individual:
    - Edit variables in `config.mk`, especially the variables in "Paths to input files"
    - Call the individual analysis Makefile via the shell script by running `sh indiv_analysis`
* When all individuals have been processed\:
    - Call the comparative analysis Makefile via the shell script by running `sh compare_analysis`

---

# Main Directory Structure

* compare\_analysis
    - Calls the Makefile in comparative analysis mode, to be run after all individuals have been processed.
* config.mk
    - User-defined variables such as paths to input FASTQ files
* data/
    - Contains FASTQ files, plus barcode data for demultiplexing [optional].
* full\_analysis.mk
    - The Makefile for the Mapping analysis. Called via `sh indiv_analysis` or `sh compare_analysis`
* genomes/
    - Contains folders, each containing an indexed genome.
* indiv\_analysis
    - Calls the Makefile in individual analysis mode, to be run once per individual.
* pbs/
    - Example PBS files for submitting jobs for the different parts of the analysis
* reports/
    - Informational reports generated as the pipeline runs
* results/
    - Output files generated as the pipeline runs
* scripts/
    - Contains all programs needed for the pipeline.
