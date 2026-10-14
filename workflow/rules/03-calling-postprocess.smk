rule bcftools_concat_chunks:
    input:
        bcfs=expand(
            "<results>/bcfs/{{caller}}/chunks/{{mapper}}_{{caller}}_chunk{chunk}.bcf",
            chunk=chunklist,
        ),
    output:
        bcf="<results>/bcfs/{caller}/{mapper}_{caller}_raw.bcf",
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
