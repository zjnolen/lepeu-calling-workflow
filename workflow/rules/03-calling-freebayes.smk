ruleorder: freebayes_bcf > bcftools_concat_chunks

rule freebayes_bcf:
    input:
        alns=expand(
            "<results>/mapped/dedup/{sample}_{{mapper}}.cram",
            sample=samples.index.tolist(),
        ),
        idxs=expand(
            "<results>/mapped/dedup/{sample}_{{mapper}}.cram.crai",
            sample=samples.index.tolist(),
        ),
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
    output:
        bcf=temp("<results>/bcfs/freebayes/{mapper}_freebayes.bcf"),
    log:
        "<logs>/freebayes/{mapper}_freebayes.bcf.log",
    threads: 24
    params:
        extra="--report-monomorphic --genotype-qualities"
    resources:
        runtime="2d"
    wrapper:
        "v9.18.0/bio/freebayes"
