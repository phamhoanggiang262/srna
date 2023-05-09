process CREATE_SAMPLEINFO {
	publishDir  "$baseDir/results", mode: 'copy'
	
	input:
	path samplesheet
	
	output:
	path 'sampleInfo.csv'			,emit: sampleInfo
	
	script:
	"""
	createSampleInfo.R --samplesheet $samplesheet --path $baseDir/results/samtools/sort
	"""	
}

