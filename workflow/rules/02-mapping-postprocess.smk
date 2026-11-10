rule markduplicates_bam:
    input:
        unpack(get_paired_bams),
    output:
        bam="<results>/bams/dedup/{sample}_{mapper}.cram",
        idx="<results>/bams/dedup/{sample}_{mapper}.cram.crai",
        metrics="<results>/bams/dedup/{sample}_{mapper}.cram.metrics.txt",
    log:
        "<logs>/picard_markdups/{sample}_{mapper}.cram.log",
    conda:
        "../envs/picard.yaml"
    threads: 2
    resources:
        runtime="1d",
    params:
        input_bams=lambda w, input: list(map("--INPUT {}".format, input.bams)),
        extra="--REMOVE_DUPLICATES true",
        samtools_opts="--output-fmt-option version=3.0",
        sam_threads=lambda wildcards, threads: max(1, threads - 1),
    shell:
        """
        picard MarkDuplicates \
            -Xmx{resources.mem_mib}M -Djava.io.tmpdir={resources.tmpdir} \
            {params.extra} \
            {params.input_bams} \
            --TMP_DIR {resources.tmpdir} \
            --OUTPUT /dev/stdout \
            --METRICS_FILE {output.metrics} \
            | samtools view {params.samtools_opts} \
                --threads {params.sam_threads} \
                --reference {input.ref} \
                --write-index \
                -o {output.bam}##idx##{output.idx} \
                --output-fmt CRAM,embed_ref &>{log}
        """


rule riker_qc:
    input:
        bam="<results>/bams/dedup/{sample}_{mapper}.cram",
        idx="<results>/bams/dedup/{sample}_{mapper}.cram.crai",
        ref=f"<results>/ref/{genome}",
    output:
        txt=[
            "<results>/bams/qc/riker/{sample}_{mapper}.alignment-metrics.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.base-distribution-by-cycle.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.isize-histogram.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.isize-metrics.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.mean-quality-by-cycle.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.quality-score-distribution.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.gcbias-detail.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.gcbias-summary.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.wgs-coverage.txt",
            "<results>/bams/qc/riker/{sample}_{mapper}.wgs-metrics.txt",
        ],
        pdf=[
            "<results>/bams/qc/riker/{sample}_{mapper}.base-distribution-by-cycle.pdf",
            "<results>/bams/qc/riker/{sample}_{mapper}.quality-score-distribution.pdf",
            "<results>/bams/qc/riker/{sample}_{mapper}.mean-quality-by-cycle.pdf",
            "<results>/bams/qc/riker/{sample}_{mapper}.isize-histogram.pdf",
            "<results>/bams/qc/riker/{sample}_{mapper}.gcbias-chart.pdf",
            "<results>/bams/qc/riker/{sample}_{mapper}.wgs-coverage.pdf",
        ],
    log:
        "<logs>/riker/{sample}_{mapper}.cram.log",
    conda:
        "../envs/riker.yaml"
    threads: 4
    resources:
        runtime="1h",
    params:
        out=lambda w, output: output[0].removesuffix(".alignment-metrics.txt"),
    shell:
        """
        riker multi --input {input.bam} --output {params.out} --reference {input.ref} \
            --threads 4 --tools wgs gcbias basic alignment isize 2>{log}

        sed -i 's/^{wildcards.sample}/{wildcards.sample}_{wildcards.mapper}/g' {output.txt}
        """
