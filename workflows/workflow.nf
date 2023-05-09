include { FASTQC                         } from '../modules/nf-core/fastqc/main'
include { TRIMGALORE                     } from '../modules/nf-core/trimgalore/main'
include { FASTP	                         } from '../modules/nf-core/fastp/main'
include { BWA_INDEX                      } from '../modules/nf-core/bwa/index/main'
include { SRNAMAPPER                     } from '../modules/local/srnamapper/main'
include { SAMTOOLS_SORT			 } from '../modules/nf-core/samtools/sort/main'
include { MMANNOT                        } from '../modules/local/mmannot/main'
include { MMQUANT                        } from '../modules/local/mmquant/main'
include { CREATE_SAMPLEINFO 		 } from '../modules/local/custom/main'
include { SRNADIFF	 		 } from '../modules/local/srnadiff/main'


//////// PARAMETERS

params.input = ""
params.annotation = "NO_FILE"

////// Function to get list of [ meta, [ fastq_1 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id           = row.SampleName

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read FastQ file does not exist!\n${row.fastq}"
    } else { fastq_meta = [ meta + ['single_end' : true], [ file(row.fastq) ] ]
    
    } 
    return fastq_meta
}



/////////// WORKFLOW //////////

workflow{

	if (params.index) {
	
	index_ch = channel.fromPath(params.index)
	index_ch.view()	
	} else {
	
	Channel.from([
		[["id" : "index"], params.genome]])
		.set {fasta_ch}
						
	BWA_INDEX(fasta_ch)
	BWA_INDEX.out.index.map{meta, index -> [index] }.set{index_ch}
	BWA_INDEX.out.index.view()
	index_ch.view()	
	}
	
	
	
	
	
	reads_ch = Channel.fromPath(params.input) \
        | splitCsv(header:true, sep:',') \
        | map { create_fastq_channel(it) }
        reads_ch.view()
        
        samplesheet_ch = Channel.fromPath(params.input)
        CREATE_SAMPLEINFO(samplesheet_ch)
        
        FASTQC(reads_ch)
        TRIMGALORE(reads_ch)
	FASTP(TRIMGALORE.out.reads, [], [], [])
	
	map_ch = FASTP.out.reads.combine(index_ch)
	map_ch.view()
	
	SRNAMAPPER(map_ch)
	
	SAMTOOLS_SORT(SRNAMAPPER.out.bam)
	
	annotation_ch = channel.fromPath(params.annotation)
	SAMTOOLS_SORT.out.bam   | map { meta, bam -> [ [ "id":"test" ], bam ] }
			   				| groupTuple ()
			  				| combine(annotation_ch)
		           			| set { bam_ch } 	
	
	if (params.annotation != "NO_FILE")
	{
		if(params.configfile){

			configfile_ch = channel.fromPath(params.configfile)
			MMANNOT(bam_ch, configfile_ch)
			SRNADIFF (CREATE_SAMPLEINFO.out.sampleInfo, SAMTOOLS_SORT.out.bam, annotation_ch )
			MMQUANT (bam_ch)
		}
		else{
			SRNADIFF (CREATE_SAMPLEINFO.out.sampleInfo, SAMTOOLS_SORT.out.bam, annotation_ch )
			MMQUANT (bam_ch)
		}
	}else{
		SRNADIFF (CREATE_SAMPLEINFO.out.sampleInfo, SAMTOOLS_SORT.out.bam, annotation_ch )
	}
	           

}



