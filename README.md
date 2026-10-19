# LepEU calling workflow

To run on one dataset:

1. edit config/config.yaml, update samples.tsv, units.tsv
2. `snakemake --sdm conda <system specific options> -n` - dry-run
3. `snakemake --sdm conda <system specific options>` - actually run

To run on multiple datasets:

1. edit config/config-multidataset.yaml, update samples.tsv, units.tsv
2. `snakemake --sdm conda --configfile config/config-multidataset.yaml --snakefile workflow/multidataset.snakefile <system specific options> -n` - dry-run
3. `snakemake --sdm conda --configfile config/config-multidataset.yaml --snakefile workflow/multidataset.snakefile <system specific options>` - actually run

A better way to deploy (snakedeploy with versioning) is on the way.
