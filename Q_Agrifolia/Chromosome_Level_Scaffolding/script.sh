#!/bin/bash

# 1. Download Q. agrifolia scaffold level assembly and the Q. rubra assemblies

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/029/955/455/GCA_029955455.1_dhQueAgri1.0.hap1/GCA_029955455.1_dhQueAgri1.0.hap1_genomic.fna.gz

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/035/136/125/GCA_035136125.1_Qrubra_687_v2.0/GCA_035136125.1_Qrubra_687_v2.0_genomic.fna.gz

# cd into Q_agrifolia directory and perform chromosome level scaffolding using RagTag.
mamba activate ragtag
ragtag.py scaffold -o QA -u -t 16 GCA_035136125.1_Qrubra_687_v2.0_genomic.fna GCA_029955455.1_dhQueAgri1.0.hap1_genomic.fna

# cd into QA directory
sed 's/_RagTag//' ragtag.scaffold.fasta > QA_renamed.scaffold.fasta


# Extract chromosome FASTA headers from Q. rubra reference genome and save to QRlist file
grep ">CM" GCA_035136125.1_Qrubra_687_v2.0_genomic.fna | cut -d " " -f 1 | sed 's/>//' > QRlist

# activate synteny mamba environment
while read i; do
    echo "$i"

    bioawk -c fastx -v chr="$i" '$name==chr{print ">"$name ; print $seq}' QA_renamed.scaffold.fasta >> QA_chr_scaffolds.fa

    echo "done"

done < QRlist


# Extract canonical chromosome sequences from Q. rubra reference genome.

while read i; do
    echo "$i"

    bioawk -c fastx -v chr="$i" '$name==chr{print ">"$name ; print $seq}' GCA_035136125.1_Qrubra_687_v2.0_genomic.fna  >> QRubra_REF.fa

    echo "done"

done < QRlist

# Activate minimap environment
minimap2 -ax asm5 -t 16 --eqx QRubra_REF.fa  QA_chr_scaffolds.fa | samtools sort -O BAM - > QR_QA.bam

samtools index QR_QA.bam

syri -c QR_QA.bam -r QRubra_REF.fa -q  QA_chr_scaffolds.fa -F B --prefix QR_QA.bam

plotsr --sr QR_QA.bamsyri.out --genomes genomes.txt -o QA_QRplot.png


# Assembly evaluation.

mamba activate quast

quast QA_renamed.scaffold.fasta -r GCA_035136125.1_Qrubra_687_v2.0_genomic.fna -o QA_quast_output_1 -t 16

quast QA_chr_scaffolds.fa -r GCA_035136125.1_Qrubra_687_v2.0_genomic.fna -o QA_quast_output_2 -t 16

mamba activate busco

export _JAVA_OPTIONS="-Xmx60g"
busco -i QA_renamed.scaffold.fasta -o QA_BUSCO_1 -l embryophyta_odb10 -m genome -c 16 
busco -i QA_chr_scaffolds.fa -o QA_BUSCO_2 -l embryophyta_odb10 -m genome -c 16 


