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
    log:
        "<logs>/bwa_mem2/{sample}_{unit}_{lib}_{plat}.log",
    threads: 24
    resources:
        runtime="1d",
    params:
        extra=r"-R '@RG\tID:{unit}.{lib}\tPU:{unit}\tSM:{sample}\tLB:{lib}\tPL:{plat}'",
        sort="samtools",
        sort_order="coordinate",
        sort_extra="",
    wrapper:
        "v9.16.0/bio/bwa-mem2/mem"
