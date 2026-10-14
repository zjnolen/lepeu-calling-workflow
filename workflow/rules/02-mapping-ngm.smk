rule ngm_index:
    input:
        "<results>/ref/{genome}",
    output:
        "<results>/ref/{genome}-enc.2.ngm",
        "<results>/ref/{genome}-ht-13-2.3.ngm",
    log:
        "<logs>/ngm_index/{genome}.log",
    conda:
        "../envs/ngm.yaml"
    threads: 12
    resources:
        runtime="12h",
    shell:
        """
        ngm -r {input} --kmer 13 --kmer-skip 2 2>{log}
        """


def get_ngm_extra(wildcards):
    extra = " ".join(
        [
            f"--rg-id {wildcards.sample}-{wildcards.unit}-{wildcards.lib}",
            f"--rg-sm {wildcards.sample}",
            f"--kmer 13",
            f"--kmer-skip 2",
            f"--rg-pl {wildcards.plat}",
        ]
    )
    return extra


rule ngm_map:
    input:
        reads=[
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.1.fastq.gz",
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.2.fastq.gz",
        ],
        ref=f"<results>/ref/{genome}",
        index=[
            f"<results>/ref/{genome}-enc.2.ngm",
            f"<results>/ref/{genome}-ht-13-2.3.ngm",
        ],
    output:
        temp("<results>/bams/mapped/{sample}_{unit}_{lib}_{plat}.ngm.cram"),
    log:
        "<logs>/ngm/{sample}_{unit}_{lib}_{plat}.log",
    benchmark:
        "<benchmarks>/ngm/{sample}_{unit}_{lib}_{plat}.log"
    conda:
        "../envs/ngm.yaml"
    threads: 24
    resources:
        runtime="1d",
    params:
        extra=get_ngm_extra,
    shell:
        """
        samtools_threads=$(({threads} - 1))

        ngm -r {input.ref} -t {threads} \
            -1 {input.reads[0]} -2 {input.reads[1]} {params.extra} \
            | samtools sort -O cram -T {resources.tmpdir} --threads $samtools_threads >{output} 2>{log}
        """


rule ngm_map_gpu:
    input:
        reads=[
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.1.fastq.gz",
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.2.fastq.gz",
        ],
        ref=f"<results>/ref/{genome}",
        index=[
            f"<results>/ref/{genome}-enc.2.ngm",
            f"<results>/ref/{genome}-ht-13-2.3.ngm",
        ],
    output:
        temp("<results>/bams/mapped/{sample}_{unit}_{lib}_{plat}.ngm-gpu.cram"),
    log:
        "<logs>/ngm-gpu/{sample}_{unit}_{lib}_{plat}.log",
    benchmark:
        "<benchmarks>/ngm-gpu/{sample}_{unit}_{lib}_{plat}.log"
    conda:
        "../envs/ngm.yaml"
    threads: 24
    resources:
        nodes=1,
        gpu=1,
        slurm_partition="gpua100i",
        runtime="1d",
    params:
        extra=get_ngm_extra,
    shell:
        """
        samtools_threads=$(({threads} - 1))

        ngm -r {input.ref} -t {threads} \
            -1 {input.reads[0]} -2 {input.reads[1]} {params.extra} -g \
            | samtools sort -O cram -T {resources.tmpdir} --threads $samtools_threads >{output} 2>{log}
        """
