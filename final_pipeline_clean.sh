#!/bin/bash
# =====================================================================
# PROJECT 4: END-TO-END MICROBIAL GENOMICS PIPELINE (MRSA STRAIN)
# Student: Ishika Sinha | Dataset: ERR14128727
# =====================================================================

echo "=== STAGE 1: DIRECTORY SETUP & RAW DATA PREPARATION ==="
mkdir -p ~/microbial_genomics/mrsa_project/raw_data
mkdir -p ~/microbial_genomics/mrsa_project/trimmed_data
mkdir -p ~/microbial_genomics/mrsa_project/reports
cd ~/microbial_genomics/mrsa_project/

# Copy raw read data from Windows Downloads directory into Linux environment
cp /mnt/c/Users/ishika/Downloads/ERR14128727* . 2>/dev/null || echo "Files already present or manually copied."

echo "=== STAGE 2: QUALITY CONTROL AND ADAPTER TRIMMING ==="
# Standard FastQC deployment on raw files
sudo apt update && sudo apt install -y fastqc
fastqc *.fastq* -o reports/

# High-throughput trimming and adapter clearing via fastp
fastp -i raw_data/ERR14128727_1.fastq.gz -I raw_data/ERR14128727_2.fastq.gz \
      -o trimmed_data/cleaned_1.fastq.gz -O trimmed_data/cleaned_2.fastq.gz \
      --html reports/fastp_report.html

echo "=== STAGE 3: DE NOVO GENOME ASSEMBLY ==="
# Stitching short reads into continuous scaffolds using SPAdes
spades.py -1 trimmed_data/cleaned_1.fastq.gz -2 trimmed_data/cleaned_2.fastq.gz \
          -o spades_output/ --isolate

echo "=== STAGE 4: QUALITY EVALUATION & FUNCTIONAL ANNOTATION ==="
# Assembly quality metrics calculation via QUAST
quast.py spades_output/scaffolds.fasta -o quast_output

# Moving into custom Conda environment profile
source ~/miniconda3/etc/profile.d/conda.sh
conda activate prokka_env

# Automated rapid microbial annotation via Prokka
prokka spades_output/scaffolds.fasta --outdir prokka_output --prefix mrsa_strain --genus Staphylococcus --species aureus --force

echo "=== STAGE 5: ANTIMICROBIAL RESISTANCE SCANNING ==="
# Synchronize updated genomic reference database
if [ ! -d "resfinder_db" ]; then
    git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git
fi

# Run ResFinder screening mechanism targeting acquired resistance parameters
run_resfinder.py -ifa spades_output/scaffolds.fasta -o resfinder_output --acquired -db_res resfinder_db

echo "=== PIPELINE COMPLETE: PRINTING FINAL CLINICAL RESULTS ==="
cat resfinder_output/ResFinder_results_tab.txt

