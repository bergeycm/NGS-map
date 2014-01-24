#!/usr/bin/sh

# Demultiplex

SABRE=/home/cmb433/exome_macaque/bin/sabre-master

READ1=data/1_S1_L001_R1_001.fastq
READ2=data/1_S1_L001_R2_001.fastq
BARCODES=data/barcode_data.txt

$SABRE/sabre pe \
	-f $READ1 \
	-r $READ2 \
	-b $BARCODES \
	-u data/unknown_barcode1.fastq \
	-w data/unknown_barcode2.fastq;