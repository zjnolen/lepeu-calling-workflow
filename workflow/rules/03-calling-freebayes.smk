ruleorder: freebayes_bcf > bcftools_concat_chunks


rule freebayes_bcf:
    input:
        alns=expand(
            "<results>/bams/dedup/{sample}_{{mapper}}.cram",
            sample=samples.index.tolist(),
        ),
        idxs=expand(
            "<results>/bams/dedup/{sample}_{{mapper}}.cram.crai",
            sample=samples.index.tolist(),
        ),
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
    output:
        bcf="<results>/bcfs/freebayes/{mapper}_freebayes_raw.bcf",
    log:
        "<logs>/freebayes/{mapper}_freebayes.bcf.log",
    benchmark:
        "<benchmarks>/freebayes/{mapper}_freebayes.log"
    threads: 24
    resources:
        runtime="2d",
    params:
        extra="--report-monomorphic --genotype-qualities",
    wrapper:
        "v9.18.0/bio/freebayes"
