#!/bin/bash

#SBATCH --job-name=gtf_filt --partition=cpuq --time=1:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --mem=1

### ----------------------------------------------------------------------------------
### Input Objects: 

INPUT_GTF="/group/bienko/annotations/human/hg38_GRCh38_p13/annotations/gencode/v43/gencode.v43.primary_assembly.basic.annotation.gtf.gz" 

WORKDIR="/group/bienko/projects/RNAFISH/Output_FunkGlist/Output_TX_ID_20241128"

GENELIST="/group/bienko/projects/RNAFISH/Output_FunkGlist/Output_TX_ID_20241128/genelist_Ivano.txt"


### ----------------------------------------------------------------------------------
### 1. Pre-Processing ----------------------------------------------------------------
### ----------------------------------------------------------------------------------

zcat ${INPUT_GTF} | grep -f ${GENELIST} | gzip > ${WORKDIR}/gencode.v43_annotation_filtered.gtf.gz
