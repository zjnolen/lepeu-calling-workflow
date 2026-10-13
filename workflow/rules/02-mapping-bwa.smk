rule bwa_mem2_index:
    input:
        "<results>/ref/{genome}",
    output:
        "<results>/ref/{genome}.0123",
        "<results>/ref/{genome}.amb",
        "<results>/ref/{genome}.ann",
        "<results>/ref/{genome}.bwt.2bit.64",
        "<results>/ref/{genome}.pac",
    log:
        "<logs>/bwa-mem2_index/{genome}.log",
    threads: 12
    resources:
        runtime="12h",
    wrapper:
        "v7.2.0/bio/bwa-mem2/index"


rule bwa_mem2:
    input:
        reads=[
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.1.fastq.gz",
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.2.fastq.gz",
        ],
        idx=multiext(
            f"<results>/ref/{genome}",
            ".amb",
            ".ann",
            ".bwt.2bit.64",
            ".pac",
            ".0123",
        ),
    output:
        temp("<results>/bams/mapped/{sample}_{unit}_{lib}_{plat}.bwamem2.cram"),
    benchmark:
        "<benchmarks>/bwa_mem2/{sample}_{unit}_{lib}_{plat}.log",
    log:
        "<logs>/bwa_mem2/{sample}_{unit}_{lib}_{plat}.log",
    threads: 24
    resources:
        runtime="1d",
    params:
        extra=r"-R '@RG\tID:{sample}.{unit}.{lib}\tPU:{unit}\tSM:{sample}\tLB:{lib}\tPL:{plat}'",
        sort="samtools",
        sort_order="coordinate",
        sort_extra="",
    wrapper:
        "v9.16.0/bio/bwa-mem2/mem"


rule minibwa_index:
    input:
        "<results>/ref/{genome}",
    output:
        "<results>/ref/{genome}.l2b",
        "<results>/ref/{genome}.mbw",
    conda:
        "../envs/minibwa.yaml"
    threads: 8
    resources:
        runtime="6h"
    shell:
        """
        minibwa index -t{threads} {input}
        """


rule minibwa_map:
    input:
        reads=[
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.1.fastq.gz",
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.2.fastq.gz",
        ],
        idx=multiext(
            f"<results>/ref/{genome}",
            ".l2b",
            ".mbw",
        ),
        ref=f"<results>/ref/{genome}",
    output:
        temp("<results>/bams/mapped/{sample}_{unit}_{lib}_{plat}.minibwa.cram"),
    benchmark:
        "<benchmarks>/minibwa/{sample}_{unit}_{lib}_{plat}.log"
    log:
        "<logs>/minibwa/{sample}_{unit}_{lib}_{plat}.log",
    conda:
        "../envs/minibwa.yaml"
    threads: 24
    resources:
        runtime="1d",
    params:
        rg=r"-R '@RG\tID:{sample}.{unit}.{lib}\tPU:{unit}\tSM:{sample}\tLB:{lib}\tPL:{plat}'",
    shell:
        """
        samtools_threads=$(({threads} - 1))

        minibwa map {params.rg} -t{threads} {input.ref} {input.reads} \
            | samtools sort -O cram -T {resources.tmpdir} --threads $samtools_threads >{output}
        """
