# Load configuration settings from an external YAML file.
# This allows users to modify parameters without changing the Snakefile.
configfile: 'config.yaml'

# Extract parameters from the configuration file.
#   subset_frac: Fraction of reads to subset to.
#   kraken_db: Path to the Kraken database.
#   reads_dir: Directory where raw sequencing reads are stored.
#   samples: List of sample names to be processed.
subset_frac = config['subset_frac']
kraken_db = config['kraken_db']
reads_dir = config['reads_dir']
samples = config['samples']

rule all:
    '''
    Final target rule that ensures the workflow runs all necessary steps.
    Produces the final visualization reports for all samples.
    '''
    input:
        expand('results/{sample}_kraken_krona_report.html', sample=samples)

rule stage_data:
    '''
    Stage reads by copying them into a structured directory.
    '''
    output:
        reads1 = 'data/{sample}_1.fastq.gz',
        reads2 = 'data/{sample}_2.fastq.gz'
    localrule:
        True
    params:
        reads_dir = reads_dir
    shell:
        '''
        cp {params.reads_dir}*{wildcards.sample}*PE.1.fastq.gz {output.reads1}
        cp {params.reads_dir}*{wildcards.sample}*PE.2.fastq.gz {output.reads2}
        '''

rule subset_reads:
    '''
    Subset a fraction of readsm. Uses seqtk to randomly sample reads.
    '''
    input:
        reads1 = rules.stage_data.output.reads1,
        reads2 = rules.stage_data.output.reads2
    output:
        subset_reads1 = 'results/{sample}_1.subset.fastq.gz',
        subset_reads2 = 'results/{sample}_2.subset.fastq.gz',
    log:
        'logs/{sample}_subset_reads.log'
    conda:
        'envs/seqtk.yaml'
    params:
        subset_frac = subset_frac
    resources:
        mem_mb = 5000,
        cpus = 1,
        time = '2:00:00'
    shell:
        '''
        seqtk sample -s seed=42 {input.reads1} {params.subset_frac} | gzip > {output.subset_reads1}
        seqtk sample -s seed=42 {input.reads2} {params.subset_frac} | gzip > {output.subset_reads2}
        '''

rule kraken:
    '''
    Classify reads using Kraken against the specified database.
    Generates a taxonomic classification report for each sample.
    '''
    input:
        reads1 = rules.subset_reads.output.subset_reads1,
        reads2 = rules.subset_reads.output.subset_reads2
    output:
        kraken_report = 'results/{sample}_kraken_report.tsv'
    conda:
        'envs/kraken.yaml'
    params:
        kraken_db = kraken_db
    resources:
        mem_mb = 60000,
        cpus = 8,
        time = '1:00:00'
    log:
        'logs/{sample}_kraken.log'
    shell:
        '''
        kraken2 \
            --db {params.kraken_db} \
            --threads {resources.cpus} \
            --gzip-compressed \
            --use-names \
            --paired \
            --report {output.kraken_report} \
            {input.reads1} \
            {input.reads2}
        '''

rule convert_kraken_report:
    '''
    Convert Kraken classification reports to Krona-compatible format.
    '''
    input:
        rules.kraken.output.kraken_report
    output:
        kraken_report_converted = 'results/{sample}_kraken_report_converted.tsv'
    conda:
        'envs/krakentools.yaml'
    localrule:
        True
    log:
        'logs/{sample}_convert_kraken_report.log'
    shell:
        '''
        kreport2krona.py -r {input} -o {output.kraken_report_converted}
        '''

rule viz_kraken:
    '''
    Produces an HTML report summarizing taxonomic classifications using Krona.
    '''
    input:
        rules.convert_kraken_report.output.kraken_report_converted
    output:
        'results/{sample}_kraken_krona_report.html'
    localrule:
        True
    conda:
        'envs/krona.yaml'
    log:
        'logs/{sample}_viz_kraken.log'
    shell:
        '''
        ktImportText {input} -o {output}
        '''

rule analyze_kraken:
    '''
    Analyze Kraken classification reports using a custom Python script.
    '''
    input:
        rules.kraken.output.kraken_report
    output:
        'results/{sample}_kraken_summary.txt'
    conda:
        'envs/pandas.yaml'
    localrule:
            True
    log:
        'logs/{sample}_analyze_kraken.log'
    script:
        'python scripts/analyze_kraken.py --input {input} --output {output}'
