#!/bin/bash

# Where QRubra_QAgrifolia.bam is the input BAM file generated from whole genome alignment of Q. rubra against Q. agrifolia
svim-asm haploid QAQR_HAP_SV QRubra_QAgrifolia.bam QRubra_REF_renamed.fa

# This will generate a variants file containing structural variants detected by svim-asm

# We use bcftools to subset only inversions

bcftools view -i 'SVTYPE="INV"' variants.vcf -O z -o svim-INV.vcf.gz

# We subset the inversions called by SyRi.

bcftools view -i 'ALT="<INV>"' /usr/scratchH/tmugoya/OAK/Q_rubra/QRubra_QA.bamsyri.vcf > SyRi-INV.vcf


mamba activate bedtools

# Use bedtools intersect to find overlapping inversions between the two call sets.
bedtools intersect \
  -a SyRi-INV.vcf.gz \
  -b svim-INV.vcf.gz \
  -f 0.50 \
  -r \
  -wa > common_INVL_pairs.vcf