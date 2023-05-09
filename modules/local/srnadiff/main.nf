process SRNADIFF {
    tag "$meta.id"
    label 'process_medium'
    publishDir  "$baseDir/results/srnadiff", mode: 'copy'
    
    conda "bioconda::bioconductor-srnadiff=1.18.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-srnadiff:1.18.0--r42hc247a5b_0':
        'quay.io/biocontainers/bioconductor-srnadiff:1.18.0--r42hc247a5b_0' }"

    input:
    path sampleInfo
    tuple val (meta), path(bamfile)
    path annotation
	
    output:
    path 'DE_regions.bed'	

    script:	
    def annotationFile = annotation.name != 'NO_FILE' ? "--annotationFile $annotation" : ''
	
    """
    srnadiff.R --sampleSheet $sampleInfo $annotationFile 
    """
    
}
