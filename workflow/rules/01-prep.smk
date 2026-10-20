rule ena_download:
    """
    If SRA accessions are the only input in a row of the units list, download
    the FASTQ files from NCBI.
    """
    output:
        fq1=temp("<results>/reads/downloaded_fastq/{accession}_1.fastq.gz"),
        fq2=temp("<results>/reads/downloaded_fastq/{accession}_2.fastq.gz"),
        info="<results>/reads/downloaded_fastq/{accession}-run-info.tsv",
    log:
        "<logs>/ena_download/{accession}.log",
    conda:
        "../envs/fastq-dl.yaml"
    resources:
        runtime="6h",
    params:
        outdir=lambda w, output: os.path.dirname(output.fq1),
    shell:
        """
        fastq-dl -a {wildcards.accession} --cpus {threads} --provider ena \
            --outdir {params.outdir} --prefix {wildcards.accession} 2>{log}
        """


rule link_genome:
    input:
        config["ref"],
    output:
        protected(f"<results>/ref/{genome}"),
    localrule: True
    resources:
        runtime="5m",
    shell:
        """
        ln -sr {input} {output}
        """


rule ref_chunking:
    """Create regions files for running in chunks along the genome"""
    output:
        "<results>/ref/chunks/chunk{chunk}.rf",
    log:
        "<logs>/ref/chunking/chunk{chunk}.log",
    localrule: True
    resources:
        runtime="5m",
    params:
        contigs=lambda w: chunks[int(w.chunk) - 1].index.tolist(),
    shell:
        r"""
        echo "{params.contigs}" | tr " " "\n" >{output} 2>{log}
        """


rule chunks2beds:
    input:
        rf="<results>/ref/chunks/chunk{chunk}.rf",
        fai=f"<results>/ref/{genome}.fai",
    output:
        "<results>/ref/chunks/chunk{chunk}.bed",
    localrule: True
    resources:
        runtime="5m",
    shell:
        """
        awk 'BEGIN {{OFS="\t"}} FNR==NR {{chrs[$1]; next}} {{for (c in chrs) if ($1 == c) print $1,0,$2}}' {input.rf} {input.fai} >{output}
        """


rule samtools_faidx:
    input:
        f"<results>/ref/{genome}",
    output:
        f"<results>/ref/{genome}.fai",
    log:
        f"<logs>/samtools/faidx/{genome}.log",
    resources:
        runtime="1h",
    params:
        extra="",
    wrapper:
        "v9.15.0/bio/samtools/faidx"


rule fastp_pe:
    input:
        unpack(get_raw_fastq),
    output:
        trimmed=[
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.1.fastq.gz",
            "<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.2.fastq.gz",
        ],
        html="<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.html",
        json="<results>/reads/trimmed/{sample}_{unit}_{lib}_{plat}.json",
    log:
        "<logs>/fastp/{sample}_{unit}_{lib}_{plat}.log",
    threads: 2
    resources:
        runtime="12h",
    wrapper:
        "v9.18.0/bio/fastp"
