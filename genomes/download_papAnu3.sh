#!/bin/sh

# Script to download baboon genome, papAnu3

mkdir genomes/papAnu3
cd genomes/papAnu3

GENOME_FA=papAnu3.fa

PAPANU3_URL=ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/264/685
PAPANU3_URL=$PAPANU3_URL/GCF_000264685.3_Panu_3.0/GCF_000264685.3_Panu_3.0_genomic.fna.gz

wget $PAPANU3_URL \
    -O ${GENOME_FA}.gz
gunzip -c ${GENOME_FA}.gz | \
    sed -e "s/^>.*chromosome \([^,]*\),.*/>chr\\1/" > \
    $GENOME_FA

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
