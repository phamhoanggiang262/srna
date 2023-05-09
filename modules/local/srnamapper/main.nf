
process SRNAMAPPER {
    tag "$meta.id"
    label 'process_long'
    publishDir  "$baseDir/results/srnamapper", mode: 'copy'

    conda "bioconda::srnamapper=1.0.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/srnamapper:1.0.8--h7132678_1':
        'quay.io/biocontainers/srnamapper:1.0.8--h7132678_1' }"

    input:
    tuple val(meta) , path(reads), path(index)

    output:
    tuple val(meta), path("*.bam")		, emit: bam
    path "versions.yml"           		, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`
    gunzip -c $reads > ${prefix}.fastq
    
    srnaMapper \\
    	-r ${prefix}.fastq \\
    	-g \$INDEX \\
    	-o ${prefix}.sam \\
    	$args \\
    	
    samtools \\
    	view \\
    	${prefix}.sam \\
    	-o ${prefix}_unsorted.bam \\
	$args2        

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        srnamapper: \$(srnaMapper -v | sed -e "s/srnaMapper v//g") 
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
