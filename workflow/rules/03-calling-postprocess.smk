rule bcftools_concat_chunks:
    input:
        bcfs=expand(
            "<results>/bcfs/{{caller}}/chunks/{{mapper}}_{{caller}}_chunk{chunk}.bcf",
            chunk=chunklist,
        ),
    output:
        bcf="<results>/bcfs/{caller}/{mapper}_{caller}.bcf",
        idx="<results>/bcfs/{caller}/{mapper}_{caller}.bcf.csi",
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    shell:
        """
        bcftools concat --threads {threads} -Ob {input.bcfs} >{output.bcf}
        bcftools index -o {output.idx} {output.bcf}
        """
