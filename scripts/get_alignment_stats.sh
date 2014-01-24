#!/bin/sh

# ------------------------------------------------------------------------------
# --- Analyze alignment output with flagstat, idxstats, and bamtools stats
# ------------------------------------------------------------------------------

# Check that input BAM and output filename were passed as parameters
USAGE="$0 input.bam output.txt";
if [ -z "$2" ]; then
	echo "ERROR: $USAGE";
	exit 1;
fi

IN_BAM=$1
REPORT=$2

echo "### --- Alignment statistics for ${IN_BAM} ----------------------" > $REPORT

# Run flagstat
echo "samtools flagstat:" >> $REPORT
$SAMTOOLS/samtools flagstat \
	$IN_BAM \
	>> $REPORT
echo "" >> $REPORT

# Run idxstats
echo "samtools idxstats:" >> $REPORT
$SAMTOOLS/samtools idxstats \
	$IN_BAM \
	>> $REPORT
echo "" >> $REPORT

# Run bamtools stats
echo "bamtools stats:" >> $REPORT
$BAMTOOLS/bamtools stats \
	-insert \
	-in $IN_BAM \
	>> $REPORT

exit;