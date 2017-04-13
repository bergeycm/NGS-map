#!/bin/sh

# Script to download macaque genome, rheMac2

mkdir genomes/rheMac2
cd genomes/rheMac2

GENOME_FA=rheMac2.fa

wget \
    'ftp://hgdownload.cse.ucsc.edu/goldenPath/rheMac2/bigZips/chromFa.tar.gz' \
    -O ${GENOME_FA}.tar.gz

tar -zxvf ${GENOME_FA}.tar.gz

cat `ls -v softMask/chr*.fa | grep -v "chrUr"` > $GENOME_FA

rm -r softMask/
rm $GENOME_FA.tar.gz

cd ../..

exit
