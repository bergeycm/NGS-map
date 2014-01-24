#!/usr/bin/sh

# Demultiplex

SABRE=/home/cmb433/exome_macaque/bin/sabre-master

READ1=data/SE_run.fastq

BARCODES=data/barcode_data_SE.txt

$SABRE/sabre se \
	-f $READ1 \
	-b $BARCODES \
	-u data/unknown_barcode_SE.fastq;