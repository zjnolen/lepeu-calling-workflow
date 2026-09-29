rule bcftools_chunk:
    input:
        crams=expand(
            "<results>/mapped/dedup/{sample}_{{mapper}}.cram",
            sample=samples.index.tolist(),
        ),
        crais=expand(
            "<results>/mapped/dedup/{sample}_{{mapper}}.cram.crai",
            sample=samples.index.tolist(),
        ),
        regs="<results>/ref/chunks/chunk{chunk}.rf",
        ref=f"<results>/ref/{genome}",
        fai=f"<results>/ref/{genome}.fai",
    output:
        bcf=temp("<results>/bcfs/{caller}/chunks/{mapper}_{caller}_chunk{chunk}.bcf"),
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    params:
        hwe=lambda w: "-G -" if f"{w.caller}" == "bcftools-nohwe" else "",
    shell:
        """
        bcftools mpileup -a "FMT/AD,FMT/DP,INFO/AD" -f {input.ref} -R {input.regs} -Ou {input.crams} \
            | bcftools call -m -a GQ,GP {params.hwe} --threads {threads} -Ob >{output.bcf}
        """


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
