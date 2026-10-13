#!/bin/bash

#  Prerequisites:
#  1. GetOrganelle (v1.7.7.1): https://github.com/Kinggerm/GetOrganelle/releases/tag/1.7.7.1. Add GetOrganelle to your PATH variable.
#  2. Install SPAdes, Bowtie2, BLAST+ 
#  3. Install additional conda dependencies in a new conda environment. Use provided getorganelle.yaml.

# Procedure
# 1. Download and initialize  plastome database for GetOrganelle
get_organelle_config.py -a embplant_pt

# 2. Download raw reads for NCBI accession SRR25495895 using the NCBI datasets CLI tool. Create and activate the datasets conda environment.

prefetch -v SRR25495895 --max-size 50G
fasterq-dump --outdir . --split-files

# 3. Run GetOrganelle.
get_organelle_from_reads.py -1 SRR25495895_1.fastq -2 SRR25495895_2.fastq -o QE_plastome --fast -F embplant_pt -t 16
