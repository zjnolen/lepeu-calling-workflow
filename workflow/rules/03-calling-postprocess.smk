rule bcftools_concat_chunks:
    input:
        bcfs=expand(
            "<results>/bcfs/bcftools-{{hwe}}/chunks/{{mapper}}_bcftools-{{hwe}}_chunk{chunk}.bcf",
            chunk=chunklist,
        ),
    output:
        bcf=temp("<results>/bcfs/bcftools-{hwe}/{mapper}_bcftools-{hwe}_raw.bcf"),
    benchmark:
        "<benchmarks>/bcftools_concat/{mapper}_bcftools-{hwe}.log"
    wildcard_constraints:
        hwe="cohort|nohwe",
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    shell:
        """
        bcftools concat --threads {threads} -Ob {input.bcfs} >{output.bcf}
        """


rule freebayes_concat_chunks:
    input:
        bcfs=expand(
            "<results>/bcfs/freebayes/chunks/{{mapper}}_freebayes_chunk{chunk}.bcf",
            chunk=chunklist,
        ),
    output:
        bcf="<results>/bcfs/freebayes/{mapper}_freebayes_raw.bcf",
    benchmark:
        "<benchmarks>/freebayes_concat/{mapper}_freebayes.log"
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    shell:
        """
        bcftools concat --threads {threads} -Ob {input.bcfs} >{output.bcf}
        """


rule gatk_concat_chunks:
    input:
        bcfs=expand(
            "<results>/bcfs/{{caller}}/chunks/{{mapper}}_{{caller}}_chunk{chunk}.vcf.gz",
            chunk=chunklist,
        ),
    output:
        bcf=temp("<results>/bcfs/{caller}/{mapper}_{caller}_raw.bcf"),
    benchmark:
        "<benchmarks>/{caller}_concat/{mapper}_{caller}.log"
    wildcard_constraints:
        caller="gatk|gatk-gpu",
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    shell:
        """
        bcftools concat --threads {threads} -Ob {input.bcfs} >{output.bcf}
        """


rule bcftools_normalize:
    input:
        bcf="<results>/bcfs/{caller}/{mapper}_{caller}_raw.bcf",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
    output:
        bcf="<results>/bcfs/{caller}/{mapper}_{caller}_raw-normed.bcf",
        idx="<results>/bcfs/{caller}/{mapper}_{caller}_raw-normed.bcf.csi",
    benchmark:
        "<benchmarks>/{caller}_normalize/{mapper}_{caller}_normalize.log"
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    shell:
        """
        bcftools norm -a -f {input.ref} --threads {threads} -Ob {input.bcf} >{output.bcf}
        bcftools index -o {output.idx} {output.bcf}
        """


rule bcftools_stats:
    input:
        "<results>/bcfs/{caller}/{mapper}_{caller}_{form}.bcf",
    output:
        "<results>/bcfs/{caller}/{mapper}_{caller}_{form}.bcf.stats",
    wildcard_constraints:
        form="raw|raw-normed",
    conda:
        "../envs/bcftools.yaml"
    threads: 1
    resources:
        runtime="6h",
    shell:
        """
        bcftools stats -s - {input} >{output}
        """
