#!/bin/bash
# Gut Microbiome Profiling in Elderly Hypertensive Patients with Chronic Kidney Disease
# QIIME2 2024.2 Workflow
# Author: Liviya Laakshi, MSC BIOTECHNOLOGY


# Stop on error and print commands
set -xe

# Activate conda environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-2024.2


# Define directories

PROJECT_DIR="/mnt/c/Users/liviy/Downloads/gut"
SRA_DIR="${PROJECT_DIR}/sra_files"
FASTQ_DIR="${PROJECT_DIR}/fastq"
QC_DIR="${PROJECT_DIR}/fastqc"
QIIME2_DIR="${PROJECT_DIR}/qiime2_results"
METADATA_FILE="${PROJECT_DIR}/sample-metadata.tsv"
MANIFEST_FILE="${PROJECT_DIR}/manifest_fixed.tsv"


# Create necessary directories

mkdir -p $SRA_DIR $FASTQ_DIR $QC_DIR $QIIME2_DIR


# Step 1: Download SRA files (uncomment when needed)

echo "Downloading SRA files..."
prefetch SRR34626586 -O $SRA_DIR
prefetch SRR34626587 -O $SRA_DIR
prefetch SRR34626589 -O $SRA_DIR
prefetch SRR34626590 -O $SRA_DIR


# Step 2: Convert SRA to FASTQ (uncomment when needed)

echo "Converting SRA to FASTQ..."
fasterq-dump --split-files -O $FASTQ_DIR $SRA_DIR/SRR34626586.sra
fasterq-dump --split-files -O $FASTQ_DIR $SRA_DIR/SRR34626587.sra
fasterq-dump --split-files -O $FASTQ_DIR $SRA_DIR/SRR34626589.sra
fasterq-dump --split-files -O $FASTQ_DIR $SRA_DIR/SRR34626590.sra


# Step 3: Quality check FASTQ files (uncomment when needed)

echo "Running FastQC..."
fastqc $FASTQ_DIR/*.fastq -o $QC_DIR


# Step 4: Import sequences into QIIME2

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $MANIFEST_FILE \
  --output-path $QIIME2_DIR/demux-paired-end.qza \
  --input-format PairedEndFastqManifestPhred33V2


# Step 5: Summarize demultiplexed sequences

qiime demux summarize \
  --i-data $QIIME2_DIR/demux-paired-end.qza \
  --o-visualization $QIIME2_DIR/demux-paired-end.qzv


# Step 6: DADA2 denoise-paired

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $QIIME2_DIR/demux-paired-end.qza \
  --p-trunc-len-f 245 \
  --p-trunc-len-r 245 \
  --o-table $QIIME2_DIR/table.qza \
  --o-representative-sequences $QIIME2_DIR/rep-seq.qza \
  --o-denoising-stats $QIIME2_DIR/denoising-stats.qza


# Step 7: Summarize feature table

qiime feature-table summarize \
  --i-table $QIIME2_DIR/table.qza \
  --o-visualization $QIIME2_DIR/table-summary.qzv \
  --m-sample-metadata-file $METADATA_FILE


# Step 8: Tabulate representative sequences

qiime feature-table tabulate-seqs \
  --i-data $QIIME2_DIR/rep-seq.qza \
  --o-visualization $QIIME2_DIR/rep-seq.qzv


# Step 9: Summarize denoising stats

qiime metadata tabulate \
  --m-input-file $QIIME2_DIR/denoising-stats.qza \
  --o-visualization $QIIME2_DIR/denoising-stats.qzv


# Step 10: Download classifier (uncomment if missing)

wget https://data.qiime2.org/2024.2/common/silva-138-99-515-806-nb-classifier.qza -P $QIIME2_DIR


# Step 11: Assign taxonomy

qiime feature-classifier classify-sklearn \
  --i-classifier $QIIME2_DIR/silva-138-99-515-806-nb-classifier.qza \
  --i-reads $QIIME2_DIR/rep-seq.qza \
  --o-classification $QIIME2_DIR/taxonomy.qza \
  --p-reads-per-batch 1000 \
  --p-n-jobs 1


# Step 12: Visualize taxonomy

qiime metadata tabulate \
  --m-input-file $QIIME2_DIR/taxonomy.qza \
  --o-visualization $QIIME2_DIR/taxonomy.qzv


# Step 13: Create taxa bar plots

qiime taxa barplot \
  --i-table $QIIME2_DIR/table.qza \
  --i-taxonomy $QIIME2_DIR/taxonomy.qza \
  --m-metadata-file $METADATA_FILE \
  --o-visualization $QIIME2_DIR/taxa-bar-plots.qzv

echo "Gut microbiome analysis completed successfully!" 

# end of file 
