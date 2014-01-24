for f in results/*.passed.realn.bam; do

	echo "Processing $f...";

	echo "1x coverage:";
	~/exome_macaque/bin/samtools-0.1.16/samtools pileup \
		$f \
		| awk '{if ($4 >= 1) print $4}' | wc -l
		
	echo "5x coverage:";
	~/exome_macaque/bin/samtools-0.1.16/samtools pileup \
		$f \
		| awk '{if ($4 >= 5) print $4}' | wc -l
	
	echo "10x coverage:";
	~/exome_macaque/bin/samtools-0.1.16/samtools pileup \
		$f \
		| awk '{if ($4 >= 10) print $4}' | wc -l
	
done;