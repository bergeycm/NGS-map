#!/bin/sh

# Script to download tarsier genome, carlitosyrichta

mkdir genomes/carlitosyrichta
cd genomes/carlitosyrichta

GENOME_FA=carlitosyrichta.fa

wget \
    'ftp://ftp.ensembl.org/pub/release-91/fasta/carlito_syrichta/dna/Carlito_syrichta.Tarsius_syrichta-2.0.1.dna_sm.toplevel.fa.gz' \
    -O ${GENOME_FA}.gz

gunzip ${GENOME_FA}.gz

cd ../..

exit
