ruleorder: gatk_parabricks > bcftools_concat_chunks


rule haplotype_caller_gvcf:
    input:
        # single or list of bam files
        bam="<results>/bams/dedup/{sample}_{mapper}.cram",
        bai="<results>/bams/dedup/{sample}_{mapper}.cram.crai",
        intervals="<results>/ref/chunks/chunk{chunk}.bed",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
        dict=f"<results>/ref/{genome_noext}.dict",
    output:
        gvcf="<results>/bcfs/gatk/sample_gvcfs/{sample}_{mapper}_gatk_chunk{chunk}.g.vcf.gz",
    log:
        "<logs>/gatk/haplotypecaller/{sample}_{mapper}_chunk{chunk}.log",
    threads: 4
    wrapper:
        "v9.19.3/bio/gatk/haplotypecaller"


rule genomics_db_import:
    input:
        gvcfs=expand(
            "<results>/bcfs/gatk/sample_gvcfs/{sample}_{{mapper}}_gatk_chunk{{chunk}}.g.vcf.gz",
            sample=samples.index.tolist(),
        ),
        intervals="<results>/ref/chunks/chunk{chunk}.bed",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
        dict=f"<results>/ref/{genome_noext}.dict",
    output:
        db=directory("<results>/bcfs/gatk/genomicsdbs/{mapper}_gatk_chunk{chunk}"),
    log:
        "<logs>/gatk/genomicsdbimport_{mapper}_chunk{chunk}.log",
    threads: 2
    resources:
        mem_mb=lambda wildcards, input: max([input.size_mb * 1.6, 200]),
    wrapper:
        "v9.19.3/bio/gatk/genomicsdbimport"


rule genotype_gvcfs:
    input:
        genomicsdb="<results>/bcfs/gatk/genomicsdbs/{mapper}_gatk_chunk{chunk}",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
        dict=f"<results>/ref/{genome_noext}.dict",
    output:
        vcf="<results>/bcfs/gatk/chunks/{mapper}_gatk_chunk{chunk}.vcf.gz",
    log:
        "<logs>/gatk/genotypegvcfs_{mapper}_chunk{chunk}.log",
    params:
        extra="--all-sites",
    wrapper:
        "v9.19.3/bio/gatk/genotypegvcfs"


rule gatk_parabricks:
    input:
        memcrams=expand(
            "<results>/bams/dedup/{sample}_bwamem2.cram",
            sample=samples.index.tolist(),
        ),
        memcrais=expand(
            "<results>/bams/dedup/{sample}_bwamem2.cram.crai",
            sample=samples.index.tolist(),
        ),
        ngmcrams=expand(
            "<results>/bams/dedup/{sample}_ngm.cram",
            sample=samples.index.tolist(),
        ),
        ngmcrais=expand(
            "<results>/bams/dedup/{sample}_ngm.cram.crai",
            sample=samples.index.tolist(),
        ),
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
        dict=f"<results>/ref/{genome_noext}.dict",
    output:
        membcf="<results>/bcfs/gatk-gpu/bwamem2_gatk-gpu_raw.bcf",
        ngmbcf="<results>/bcfs/gatk-gpu/ngm_gatk-gpu_raw.bcf",
    benchmark:
        "<benchmarks>/gatk-gpu/gatk-gpu.log"
    conda:
        "../envs/gatk.yaml"
    threads: 48
    resources:
        slurm_partition="gpua100",
        runtime="1d",
    shell:
        r"""
        mkdir -p {resources.tmpdir}/hc
        mkdir -p {resources.tmpdir}/temp
        for i in {input.memcrams} {input.ngmcrams}; do
            samp=$(basename $i | sed 's/\.cram//')
            singularity exec --nv -B /lunarc,/local docker://nvcr.io/nvidia/clara/clara-parabricks:4.8.0-1 \
                pbrun haplotypecaller --ref {input.ref} --in-bam $i --gvcf --tmp-dir {resources.tmpdir}/temp \
                --out-variants {resources.tmpdir}/hc/${{samp}}.g.vcf.gz
        done

        cut -f1 {input.fai} >{resources.tmpdir}/hc/intervals.list
        for i in {resources.tmpdir}/hc/*bwamem2.g.vcf.gz; do echo -e "$(basename $i | cut -f1 -d"_")\t$i"; done >{resources.tmpdir}/hc/bwamem2.map
        for i in {resources.tmpdir}/hc/*ngm.g.vcf.gz; do echo -e "$(basename $i | cut -f1 -d"_")\t$i"; done >{resources.tmpdir}/hc/ngm.map

        parallel -j 24 gatk --java-options "-Xmx4g" GenomicsDBImport --sample-name-map {resources.tmpdir}/hc/bwamem2.map --genomicsdb-workspace-path {resources.tmpdir}/hc/bwamem2-db-{{}} -L {{}} --tmp-dir {resources.tmpdir}/temp <{resources.tmpdir}/hc/intervals.list &
        parallel -j 24 gatk --java-options "-Xmx4g" GenomicsDBImport --sample-name-map {resources.tmpdir}/hc/ngm.map --genomicsdb-workspace-path {resources.tmpdir}/hc/ngm-db-{{}} -L {{}} --tmp-dir {resources.tmpdir}/temp <{resources.tmpdir}/hc/intervals.list &

        wait

        parallel -j 24 gatk --java-options "-Xmx4g" GenotypeGVCFs -R {input.ref} -V gendb://{resources.tmpdir}/hc/bwamem2-db-{{}} --all-sites -L {{}} -O {resources.tmpdir}/hc/bwamem2-{{}}.vcf.gz --tmp-dir {resources.tmpdir}/temp <{resources.tmpdir}/hc/intervals.list &
        parallel -j 24 gatk --java-options "-Xmx4g" GenotypeGVCFs -R {input.ref} -V gendb://{resources.tmpdir}/hc/ngm-db-{{}} --all-sites -L {{}} -O {resources.tmpdir}/hc/ngm-{{}}.vcf.gz --tmp-dir {resources.tmpdir}/temp <{resources.tmpdir}/hc/intervals.list &

        wait

        bcftools concat --threads 4 -Ob $(while read line; do echo {resources.tmpdir}/hc/bwamem2-${{line}}.vcf.gz; done <{resources.tmpdir}/hc/intervals.list) >{output.membcf}
        bcftools concat --threads 4 -Ob $(while read line; do echo {resources.tmpdir}/hc/ngm-${{line}}.vcf.gz; done <{resources.tmpdir}/hc/intervals.list) >{output.ngmbcf}
        """
