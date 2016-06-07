#!/bin/sh

# Script to download baboon genome, papAnu2

mkdir genomes/papAnu2
cd genomes/papAnu2

GENOME_FA=papAnu2.fa

wget \
    'ftp://hgdownload.cse.ucsc.edu/goldenPath/papAnu2/bigZips/papAnu2.fa.gz' \
    -O ${GENOME_FA}.gz

gunzip ${GENOME_FA}.gz


echo "Getting rid of unassembled stuff..." >&2

LAST_OK_LINE=$((`grep -n "^>[^c]" $GENOME_FA | head -n 1 | cut -d":" -f 1` - 1))
if [ $LAST_OK_LINE -gt 0 ]; then
    mv $GENOME_FA ${GENOME_FA}.backup
    head -n $LAST_OK_LINE ${GENOME_FA}.backup > ${GENOME_FA}
    rm ${GENOME_FA}.backup
fi

mkdir tmp_for_sort
faSplit byname ${GENOME_FA} tmp_for_sort/
cd tmp_for_sort/;
ls -v | xargs cat > ../${GENOME_FA}
cd ..
rm -r tmp_for_sort
