# LepEU calling workflow

A snakemake workflow for testing various aligners and callers to benchmark
bioinformatic workflows for processing LepEU data. 

## Deploying

Set up a conda environment with snakemake, snakedeploy, and the executor plugin
you need (SLURM used as an example):

```bash
conda create -n lepeu-snakemake -c conda-forge -c bioconda \
    snakemake snakedeploy snakemake-executor-plugin-slurm
```

Activate the conda environment `conda activate lepeu-snakemake` and then deploy
the workflow:

```bash
snakedeploy deploy-workflow https://github.com/zjnolen/lepeu-calling-workflow lepeu-calling-workflow --tag v0.2.0-alpha
```

You should have the workflow now deployed in `lepeu-calling-workflow` (you can change
this to another name as you prefer in the command). You can run snakemake from inside
this directory after configuring your run.

## Configuration

Here is an example configuration

```yaml
dataset: "csemiargus"

csemiargus:
  samples: "config/samples_csemiargus.tsv"
  units: "config/units.tsv"
  ref: "resources/refs/GCA_905187585.1_ilCyaSemi1.1_genomic.fna"

mappers: ["bwamem2", "ngm"]

callers: ["bcftools-cohort", "bcftools-nohwe", "freebayes", "gatk", "gatk-gpu"]
```

Results will be output to `results/{dataset}` where `{dataset}` takes on the string
configured as the dataset in the config. To configure the sample list, unit list
and ref for a dataset, input these under a header with the dataset name, i.e. for
dataset "csemiargus" above, these values are filled in under `csemiargus:`. This
allows multiple dataset configs to live in one `config.yaml`, for example:

```yaml
dataset: "csemiargus"

picarus:
  samples: "config/samples_picarus.tsv"
  units: "config/units.tsv"
  ref: "resources/refs/GCA_937595015.1_ilPolIcar1.1_genomic.fna"
csemiargus:
  samples: "config/samples_csemiargus.tsv"
  units: "config/units.tsv"
  ref: "resources/refs/GCA_905187585.1_ilCyaSemi1.1_genomic.fna"
pargus:
  samples: "config/samples_pargus.tsv"
  units: "config/units.tsv"
  ref: "resources/refs/GCA_905404155.3_ilPleArgu1.3_genomic.fna"
```

In this case all the datasets stay in one file and you define which to run by setting the
`dataset:` value. See the Running section below for how to use command line args to set
the dataset.

`mappers:` and `callers:` lists all mapping and calling tools to run, all combinations
of mappers and callers will be run for the dataset.

`samples:` and `units:` point to tab separated tables containing the sample data:

`samples.tsv` contains one entry per sample (and optionally a population; not currently
used/required):
```text
sample	population
csemiargus1	pop1
csemiargus2	pop1
```

`units.tsv` containes one entry per set of paired end sequencing reads and has the
associated sample, the platform unite (i.e. lane), library ID, platform (usually
ILLUMINA), and the SRA run accession to download:
```text
sample	unit	lib	platform	sra
csemiargus1	unit1	lib1	ILLUMINA	SRR34948887
csemiargus1	unit1	lib2	ILLUMINA	SRR34948894
csemiargus2	unit1	lib1	ILLUMINA	SRR34948899
```

If a sample has more than one entry in the units list, the reads will be mapped
independently and then merged. While samples can appear more than once in this
file, the combination of sample+unit+lib+platform must be unique per line (see
above example where csemiargus1 has two lines, with with lib1 and one with lib2).

## Running

Dry run: `snakemake --sdm conda <system specific options> -n`
Real run: `snakemake --sdm conda <system specific options>`

The run will perform all combinations of mappers and callers in the config on the the
dataset value set in `dataset:` in the config. Configuration for more than one dataset
can live on in one `config.yaml`, but only the one mentioned in `dataset:` at run time
will be run.

To more easily deploy multiple datasets without having to edit `dataset:` before each
run, you can override this config with the `--config` arg:

`snakemake --sdm conda --config dataset="csemiargus" <system specific options>`

Or, you could also make a config file for each dataset instead of putting them all in one,
just use the `--configfile` option to point to the config file for each run:

`snakemake --sdm conda --configfile config/config_csemiargus.yaml <system specific options>`

You can run multiple instances of snakemake in the same directory on different datasets, so
long as the configured value of `dataset` differs between each run in one of these ways. Be
wary that the runs don't know about each other, so limits on jobs need to be set with that
in mind (e.g. if you have a max of 300 concurrent jobs and are running three datasets at once,
set `--jobs` to 100 in each rather than 300).

### Profiles

This deployment will include a profile configuration to run on LUNARC for our allocation by
simply running:

```bash
snakemake --sdm conda --config dataset="csemiargus" --profile profiles/lepeu-lunarc
```

Feel free to copy this profile to a new folder and edit the config file
to adapt it to your cluster. Then load it when you run snakemake with the
same `--profile` option.

## Notes

The `gatk-gpu` caller which uses parabricks is somewhat locked down to LUNARC, with code
that hard codes paths and uses expectations for the node local storage that might make it
perform poorly on other systems (e.g. that each job has a unique temp folder coded to $TMPDIR).
This is to put everything into one job and avoid writing intermediate files to the shared disk,
saving space and time. If running on another system `gatk` is likely the better option, as it
avoids these hard codes, but it's slower. You can also try adapting the rule to your system if
you have GPUs available. I will try to make it more adaptable once I better understand
[this Snakemake feature](https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#auto-grouping-via-temp-files-upon-remote-execution).
