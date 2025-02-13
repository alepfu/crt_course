import pandas as pd
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()

kraken_report = args.input
summary_report = args.output

# Load Kraken report into Pandas dataframe
df = pd.read_csv(kraken_report, sep='\t', header=None)
df.columns = ['percent', 'reads_count', 'kmers', 'uniq_reads', 'tax_id', 'taxonomy']

# Compute basic statistics
total_reads = df['reads_count'].sum()
classified_reads = df[df['tax_id'] != 0]['reads_count'].sum()
unclassified_reads = total_reads - classified_reads
top_taxa = df.nlargest(10, 'reads_count')[['taxonomy', 'reads_count']]

with open(summary_report, 'w') as f:
    f.write(f"Total reads: {total_reads}\n")
    f.write(f"Classified reads: {classified_reads} ({(classified_reads/total_reads)*100:.2f}%)\n")
    f.write(f"Unclassified reads: {unclassified_reads} ({(unclassified_reads/total_reads)*100:.2f}%)\n")
    f.write("\nTop 10 Taxa:\n")
    f.write(top_taxa.to_string(index=False))
