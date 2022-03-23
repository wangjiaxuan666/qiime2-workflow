#!/bin/bash
#start copy at cat on the line below excluding the #

cat > qsubmit_qiime2.sh<<'EOF'
#!/bin/bash
#$ -S /bin/bash
#$ -o qiime2.log
#$ -e qiime2.err
#$ -cwd

# User Parameters--------
export READS=/turnbaugh/qb3share/SequencingData/000000_DummyData/amplicon/ #测序数据下机的位置
export suffix="fastq.gz" # 序列文件的后缀名
export TRIMADAPTERS=false #是否需要去除接头
export Fprimer="GTGCCAGCMGCCGCGGTAA" #515F, replace if different primer
export Rprimer="GGACTACHVGGGTWTCTAAT" #806R, replace if different primer
export FR_cut_tail=200 #equivalent to p-trunc-len-f
export RR_cut_tail=150 #equivalent to p-trunc-len-r
export FR_cut_head=20 #equivalent to trim-left-f, updated to 0 as primers already stripped
export RR_cut_head=20 #equivalent to trim-left-r, updated to 0 as primers already stripped
export Ncore=4
#------------------------

echo $(date) Running on $(hostname)
echo $(date) Loading QIIME2 environment
conda activate qiime2-2022.2
export TMPDIR=$(mktemp -d ./qiime-tmp_XXXXXXXX)
bash qiime2_wk_main.sh
Rscript -e "rmarkdown::render('QIIME2_pipeline.Rmd')"
rm qsubmit.sh
EOF
bash qsubmit.sh
# end copy here