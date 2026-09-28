from snakemake.utils import min_version
import pandas as pd
import itertools
import os

min_version("9.27.0")


configfile: "config/config.yaml"


samples = pd.read_table(config["samples"], dtype=str, comment="#").set_index(
    "sample", drop=False
)

units = pd.read_table(config["units"])
units = units[units["sample"].isin(samples.index.tolist())]


genome = os.path.basename(config["ref"])


# divide reference genome into chunks for parallelization
def chunkify(reference_fasta):
    # Open reference fasta and get list of contigs and lengths
    contigs = []
    with open(reference_fasta, "r") as fasta_in:
        for header, seq in itertools.groupby(fasta_in, lambda x: x.startswith(">")):
            if header:
                contig = next(seq).strip(">").strip().split(maxsplit=1)[0]
            seq_length = len("".join(seq).replace("\n", ""))
            if seq_length > 0:
                contigs = contigs + [[contig, seq_length]]
    df = pd.DataFrame(contigs, columns=["contig", "length"]).set_index("contig")
    # Set chunk size to just over the largest contig or 10Mb to avoid huge number of
    # chunks in fragmented genome
    chunk_size = max(max(df["length"]) + 1, 10000000)
    # Prepare list of chunk dataframes
    dfs = []
    included = []
    total = 0
    # Add contigs to chunks, starting new chunk when adding a contig would take it over
    # the configured chunk size
    for n, (index, row) in enumerate(df.iterrows()):
        total += row["length"]
        if total > chunk_size:
            new_df = pd.DataFrame(included)
            dfs.append(new_df)
            included = []
            total = row["length"]
        included.append(row)
        if ((n + 1) == len(df)) and included:
            new_df = pd.DataFrame(included)
            dfs.append(new_df)
    return dfs


chunks = chunkify(config["ref"])
chunklist = list(range(1, len(chunks) + 1))


def get_raw_fastq(wildcards):
    if "fq1" in units:
        unit = units.loc[
            (units["sample"] == wildcards.sample)
            & (units["unit"] == wildcards.unit)
            & (units["lib"] == wildcards.lib)
            & (units["platform"] == wildcards.plat),
            ["sample", "fq1", "fq2"],
        ].set_index("sample")
        if not pd.isna(unit.fq1.item()):
            return {"sample": [unit.fq1.item(), unit.fq2.item()]}
    if "sra" in units:
        sra = units[
            (units["sample"] == wildcards.sample)
            & (units["unit"] == wildcards.unit)
            & (units["lib"] == wildcards.lib)
            & (units["platform"] == wildcards.plat)
        ].sra.item()
        if not pd.isna(sra):
            return {
                "sample": [
                    f"<results>/reads/downloaded_fastq/{sra}_1.fastq.gz",
                    f"<results>/reads/downloaded_fastq/{sra}_2.fastq.gz",
                ]
            }


def get_paired_bams(wildcards):
    reads = units.loc[units["sample"] == wildcards.sample]
    combos = reads[["sample", "unit", "lib", "platform"]].agg("_".join, axis=1)
    return {
        "bams": expand("<results>/bams/mapped/{combo}.{{mapper}}.cram", combo=combos),
        "ref": f"<results>/ref/{genome}",
    }
