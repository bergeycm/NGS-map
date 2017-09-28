#!/bin/sh

# ------------------------------------------------------------------------------
# --- Index genome
# ------------------------------------------------------------------------------

# Check that genome was passed as parameter
USAGE="$0 genome.fa";
if [ -z "$1" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

# Index with BWA. 
# Output is *.fa.amb *.fa.ann *.fa.bwt *.fa.pac *.fa.sa
bwa index -a bwtsw $1

# Index with samtools. 
# Output is *.fa.fai
samtools faidx $1

# Rename index files to remove ".fa"
for file in $1.*; do
	cp $file $(echo $file | sed "s/\.fa//")
done

exit;