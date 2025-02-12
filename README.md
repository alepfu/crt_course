# Kraken Taxonomic Annotation Pipeline with Krona Visualization

## Overview

This Snakemake workflow performs taxonomic annotation of paired-end reads using Kraken2, followed by visualization of the results with Krona. Additionally, a rarefaction step is applied before analysis, using the `subset_frac` parameter to subsample reads.

This workflow is designed for SLURM-based HPC clusters and supports configuration via two separate files:

1. `config.yaml` - Workflow parameters (samples, paths, and subset fraction).
2. `profile/slurm/config.yaml` - SLURM cluster settings

## Directory Structure

```
/project-directory
│── Snakefile                 # Snakemake workflow definition
│── config.yaml               # Workflow-specific configuration (input files, subset_frac, etc.)
│── profile/slurm/config.yaml # SLURM cluster settings
│── README.md                 # Instructions and usage guide
│── results/                  # Output directory
│── data/                     # Processed data storage
└── original_data/             # Raw input data (not modified by workflow)
```

## Configuration Files

### 1. Workflow Parameters: `config.yaml`

Users should modify this file to define input directories, sample names, and processing parameters.

#### Example `config.yaml`

```yaml
subset_frac: 0.01
kraken_db: '/lisc/scratch/mirror/kraken2/kraken_standard_db/'
reads_dir: '/lisc/project/cube/prospectomics/original_data/metagenomics/rodrigues-soares_2024-06-28/'
samples:
  - 'Z12-C14'
```

- `subset_frac`: Fraction of reads to retain for rarefaction.
- `kraken_db`: Path to the Kraken2 database.
- `reads_dir`: Path to the directory containing raw reads.
- `samples`: List of sample IDs to process.

### 2. SLURM Profile: `profile/slurm/config.yaml`

This file contains SLURM job submission settings. Users should adjust these settings based on their cluster requirements.

#### Example `profile/slurm/config.yaml`

```yaml
executor: "slurm"
default-resources:
  - account=pfundner
  - time=01:00:00
  - mem_mb=1000
  - cpus=1
  - name=smk-{rule}
  - mail-type=ALL
  - mail-user=your.email@example.com
cluster-cancel: "scancel"
```

- `account`: SLURM account name.
- `time`: Maximum time per job.
- `mem_mb`: Memory allocation per job.
- `cpus`: Number of CPUs per job.
- `name`: Naming pattern for SLURM jobs.
- `mail-type`: SLURM notifications (`ALL` for all events).
- `mail-user`: Email for SLURM job notifications.

## Running the Workflow

1. Make sure Conda and Snakemake is available

2. Edit the `config.yaml` file:

- Adjust sample names, file paths, and parameters.

3. Submit the Snakemake workflow using the SLURM profile:

```bash
snakemake --profile profile/slurm
```

## Expected Outputs

The workflow generates the following results:

| File                                        | Description                                         |
| ------------------------------------------- | --------------------------------------------------- |
| `results/{sample}_kraken_krona_report.html` | Krona visualization of Kraken taxonomic annotations |
| `data/{sample}_1.fastq.gz`                  | Subsampled (rarefied) forward reads                 |
| `data/{sample}_2.fastq.gz`                  | Subsampled (rarefied) reverse reads                 |
| `results/{sample}_kraken_report.tsv`        | Kraken2 raw classification report                   |
| `results/{sample}_kraken_report_converted.tsv`        | Kraken2 classification report converted for use with Krona                   |


## Credits & License

- Author: Alexander Pfundner
- License: GPL
- Kraken2: Developed by Wood & Salzberg (2019)
- Krona: Developed by Ondov et al. (2011)
