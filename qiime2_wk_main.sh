#!/bin/bash

mkdir qiime2_result
cd qiime2_result
# Step1 data import
# 导入数据，质量值常为大写字母的Phred33版本的，也是最常见的
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path example_rawdata/filepath.manifest1 \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path import_data.qza

# Step2 Demultiplexing sequences
qiime demux summarize \
  --i-data ./import_data.qza \
  --o-visualization ./qc_visualizers.qzv

# Step3 trim and denoise
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs import_data.qza \
  --o-denoising-stats denoise_stat.qza \
  --output-dir dada2_denoise_out \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 207 \
  --p-trunc-len-r 137

# Step4 create feature tabel
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file ../example_rawdata/sample-metadata.tsv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

qiime metadata tabulate \
  --m-input-file denoise_stat.qza \
  --o-visualization denoise_stat.qzv

# Step5 phylogeny tree and distance matrix
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# Step6 alpha diversity analysis
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 2000 \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --output-dir core-metrics-results

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 4000 \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --o-visualization alpha-rarefaction.qzv


# Step7 beta diversity analysis

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --m-metadata-column time \
  --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
  --p-pairwise

qiime emperor plot \
  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --p-custom-axes dpw \
  --o-visualization core-metrics-results/unweighted-unifrac-emperor-days-since-experiment-start.qzv

qiime emperor plot \
  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --p-custom-axes dpw \
  --o-visualization core-metrics-results/bray-curtis-emperor-days-since-experiment-start.qzv

# Step8 taxonomy annotation
qiime feature-classifier classify-sklearn \
  --i-classifier ../refer_Data/silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

qiime composition add-pseudocount \
  --i-table table.qza \
  --o-composition-table comp-table.qza

# Step9 different expresion analysis
qiime composition ancom \
  --i-table comp-table.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --m-metadata-column time \
  --o-visualization ancom-subject.qzv

qiime taxa collapse \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 5 \
  --o-collapsed-table table-l5.qza

qiime composition add-pseudocount \
  --i-table table-l5.qza \
  --o-composition-table comp-table-l5.qza

qiime composition ancom \
  --i-table comp-table-l5.qza \
  --m-metadata-file ../example_rawdata/sample-metadata.tsv \
  --m-metadata-column time \
  --o-visualization l5-ancom-subject.qzv

