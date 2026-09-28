rule markduplicates_bam:
    input:
        unpack(get_paired_bams),
    output:
        bam="<results>/mapped/dedup/{sample}_{mapper}.cram",
        idx="<results>/mapped/dedup/{sample}_{mapper}.cram.crai",
        metrics="<results>/mapped/dedup/{sample}_{mapper}.cram.metrics.txt",
    log:
        "<logs>/{sample}_{mapper}.cram.log",
    resources:
        runtime="1d",
    params:
        extra="--REMOVE_DUPLICATES true",
        embed_ref=True,  # set true if the fasta reference should be embedded into the cram
        samtools_opts="--output-fmt-option version=3.0",
        withmatecigar=False,
    wrapper:
        "v9.16.0/bio/picard/markduplicates"
