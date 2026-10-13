#!/bin/bash


# 1. Download Q. engelmannii scaffold level assembly and the Q. lobata assemblies

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/633/185/GCF_001633185.2_ValleyOak3.2/GCF_001633185.2_ValleyOak3.2_genomic.fna.gz && gunzip GCF_001633185.2_ValleyOak3.2_genomic.fna.gz

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/029/955/605/GCA_029955605.1_dhQueEnge1.0.hap1/GCA_029955605.1_dhQueEnge1.0.hap1_genomic.fna.gz && gunzip GCA_029955605.1_dhQueEnge1.0.hap1_genomic.fna.gz



# cd into Q_engelmannii directory and perform chromosome level scaffolding using RagTag.
mamba activate ragtag

ragtag.py scaffold -o QE-RAGTAG -t 16 GCF_001633185.2_ValleyOak3.2_genomic.fna GCA_029955605.1_dhQueEnge1.0.hap1_genomic.fna

# remove ragtag suffix from scaffold names
sed 's/_RagTag//' QE-RAGTAG/ragtag.scaffold.fasta > QE_rename.scaffold.fasta

# extract chromosome contigs from reference
grep "^>NC_*" GCF_001633185.2_ValleyOak3.2_genomic.fna | awk -F " " '{print $1}' > QL_chrlist

# NOTE Remove ">" from the beginning of each line in QL_chrlist


# extract chromosome contigs from scaffold
while read i; do
    echo "$i"

    bioawk -c fastx -v chr="$i" '$name==chr{print ">"$name ; print $seq}' GCF_001633185.2_ValleyOak3.2_genomic.fna >> QL_reference.fa

    echo "done"

done < QL_chrlist

while read i; do
    echo "$i"

    bioawk -c fastx -v chr="$i" '$name==chr{print ">"$name ; print $seq}' QE_rename.scaffold.fasta >> QE_chr_scaffolds.fa

    echo "done"

done < QL_chrlist

# whole genome alignment with minimap
# activate minimap mamba environment

mamba activate minimap
minimap2 -ax asm5 -t 16 --eqx QL_reference.fa QE_chr_scaffolds.fa | samtools sort -O BAM - > QL_QE.bam

mamba activate synteny
syri -c QL_QE.bam -r QL_reference.fa -q QE_chr_scaffolds.fa -F B --prefix QL_QE &

plotsr --sr QL_QEsyri.out --genomes genomes.txt -o QE_QLplot.png


# Assembly evaluation.

mamba activate quast

quast QE_rename.scaffold.fasta -r GCF_001633185.2_ValleyOak3.2_genomic.fna -o QE_quast_output_1 -t 16

quast QE_chr_scaffolds.fa -r GCF_001633185.2_ValleyOak3.2_genomic.fna -o QE_quast_output_2 -t 16


mamba activate busco

export _JAVA_OPTIONS="-Xmx60g"
busco -i QE_rename.scaffold.fasta -o QE_BUSCO_1 -l embryophyta_odb10 -m genome -c 16 
busco -i QE_chr_scaffolds.fa -o QE_BUSCO_2 -l embryophyta_odb10 -m genome -c 16 


