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
        bcf=temp(
            "<results>/bcfs/bcftools-{hwe}/chunks/{mapper}_bcftools-{hwe}_chunk{chunk}.bcf"
        ),
    wildcard_constraints:
        hwe="cohort|nohwe",
    conda:
        "../envs/bcftools.yaml"
    threads: 2
    resources:
        runtime="1d",
    params:
        hwe=lambda w: "-G -" if f"{w.hwe}" == "nohwe" else "",
    shell:
        """
        bcftools mpileup -a "FMT/AD,FMT/DP,INFO/AD" -f {input.ref} -R {input.regs} -Ou {input.crams} \
            | bcftools call -m -a GQ,GP {params.hwe} --threads {threads} -Ob >{output.bcf}
        """
