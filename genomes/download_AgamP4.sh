#!/bin/sh

# Script to download Anopheles gambiae genome, PEST, AgamP4

mkdir AgamP4
cd AgamP4

GENOME_FA=AgamP4.fa

AGAM_URL=https://www.vectorbase.org/sites/default/files/ftp/downloads/
AGAM_URL=${AGAM_URL}Anopheles-gambiae-PEST_CHROMOSOMES_AgamP4.fa.gz

wget $AGAM_URL \
    -O ${GENOME_FA}.gz
gunzip ${GENOME_FA}.gz

echo "Getting rid of UNKN, Y, and MT stuff..." >&2

export PATH=$PATH:$HOME/bin/kent

mkdir tmp_for_sort
faSplit byname ${GENOME_FA} tmp_for_sort/
cd tmp_for_sort/
rm Mt.fa UNKN.fa Y_unplaced.fa
ls -v | xargs cat > ../${GENOME_FA}
cd ..
rm -r tmp_for_sort
