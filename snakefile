configfile: 'config.yaml'

subset_frac = config['subset_frac']
kraken_db = config['kraken_db']
reads_dir = config['reads_dir']
samples = config['samples']

rule all:
    input:
        expand('results/{sample}_kraken_krona_report.html', sample=samples)

rule stage_data:
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
