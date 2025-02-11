
subset_frac = 0.01
kraken_db = '/lisc/scratch/mirror/kraken2/kraken_standard_db/'
kaiju_db = '/lisc/project/cube/prospectomics/databases/kaiju_nr/'


rule all:
    input:
        expand('results/{sample}_kraken_krona_report.html')
        #expand('results/{sample}_kaiju_krona_report.html')

rule subset_reads:
    input:
        reads1 = 'data/{sample}_1.fastq.gz',
        reads2 = 'data/{sample}_2.fastq.gz'
    output:
        subset_reads1 = 'results/{sample}_1.subset.fastq.gz',
        subset_reads2 = 'results/{sample}_2.subset.fastq.gz',
    log:
        'logs/{sample}_subset_reads.log'
    conda:
        'envs/seqtk.yml'
    params:
        subset_frac = subset_frac
    resources:
        mem_mb = 5000,
        cpus = 1,
        time = '2:00:00'
    shell:
        '''
        seqtk sample -s seed=42 {input.reads_1} {params.subset_frac} | gzip > {output.subset_reads1}
        seqtk sample -s seed=42 {input.reads_2} {params.subset_frac} | gzip > {output.subset_reads2}
        '''

rule kraken:
    input:
        reads1 = rules.subset_reads.output.subset_reads1,
        reads2 = rules.subset_reads.output.subset_reads2
    output:
        kraken_report = 'results/{sample}_kraken_report.tsv'
    conda:
        'envs/kraken.yml'
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
            --report {ouput.kraken_report} \
            {input.reads1} \
            {input.reads2}
        '''

rule convert_kraken_report:
    input:
        rules.kraken.output.kraken_report
    output:
        kraken_report_converted = 'results/{sample}_kraken_report_converted.tsv'
    conda:
        'envs/krakentools.yml'
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
        'envs/krona.yml'
    log:
        'logs/{sample}_viz_kraken.log'
    shell:
        '''
        ktImportText {input} -o {output}
        '''
