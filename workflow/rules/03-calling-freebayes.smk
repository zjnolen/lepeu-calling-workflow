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
        regions="<results>/ref/chunks/chunk{chunk}.bed",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
    output:
        bcf=temp("<results>/bcfs/freebayes/chunks/{mapper}_freebayes_chunk{chunk}.bcf"),
    log:
        "<logs>/freebayes/{mapper}_freebayes_chunk{chunk}.bcf.log",
    benchmark:
        "<benchmarks>/freebayes/{mapper}_freebayes_chunk{chunk}.log"
    threads: 12
    resources:
        runtime="3d",
    params:
        extra="--report-monomorphic --genotype-qualities",
    wrapper:
        "v9.18.0/bio/freebayes"
