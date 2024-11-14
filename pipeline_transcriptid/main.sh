#!/bin/bash

#SBATCH --job-name=prb_main --partition=cpuq --time=99:00:00
#SBATCH --nodes=1 --ntasks-per-node=5 --mem=2G


### Importing Pipeline Modules
#modules connected to https://github.com/salvzzz/prb_parallel/tree/main
PIPELINE_MODS="/group/bienko/projects/RNAFISH/Scripts_PRB_git/prb_parallel/pipeline_transcriptid/modules"

echo -e "Importing Pipeline Modules:" && for MOD in ${PIPELINE_MODS}/*.sh; do source ${MOD}; done


#define directories
GENOME="/group/bienko/annotations/human/hg38_GRCh38_p13/genome/Homo_sapiens.GRCh38.103.fa.gz"
ANNOT_INPUT="/group/bienko/annotations/human/hg38_GRCh38_p13/annotations/gencode/v43/gencode.v43.primary_assembly.basic.annotation.gtf.gz" 
WORKDIR="/group/bienko/projects/RNAFISH/test_tmp/"
OLIGO_LENGTH=40


### ----------------------------------------------------------------------------------
### Pre-Processing -------------------------------------------------------------------
### ----------------------------------------------------------------------------------

### 1. Extracting input objects from provided GTF file:
parseGTF -a ${ANNOT_INPUT} -w ${WORKDIR} -o prb_id.txt.gz

    ### Debug - using only the first 3 genes to see if it works
    zcat ${WORKDIR}/prb_id.txt.gz | head -n 3 | gzip > ${WORKDIR}/id.txt.gz

### 2. Running pre-processing steps on each transcript id
time zcat "${WORKDIR}/id.txt.gz" | while IFS= read -r ID; do
    prbDesign001 -i "${ID}" -g "${GENOME}" -a "${ANNOT_INPUT}" -w "${WORKDIR}" --ccds-only
    prbDesign002 -i "${ID}" -g "${GENOME}" -l "${OLIGO_LENGTH}" -w "${WORKDIR}"
done

### 3. Creating genome and blacklist reference objects
prbReferenceCreate -w ${WORKDIR} -g ${GENOME} -l ${OLIGO_LENGTH} 

### 4. Creating HUSH temporary reference files
if [[ ! -f "${WORKDIR}/data/ref/genome.fa.aD" ]]; then
   prbReferenceHush -w ${WORKDIR} ; slurmBlocker --job-name "prbReferenceHush" -s 5
fi

### 5. Linking reference objects to each sub-directory
prbReferenceLinker -w ${WORKDIR}


### ----------------------------------------------------------------------------------
### ----------------------------------------------------------------------------------
### ----------------------------------------------------------------------------------

#output genes from gene_list with empty split/ENSG*/data/rois/all_regions_tsv 
# echo " Looking for genes with have empty rois tsv ..."
# wc -l split/*/*/data/rois/all_regions.tsv | awk '$1 == 1 {print $2}' | cut -d'/' -f 2 


   #### not seen yet ---->




# #  ##step nHUSH (mers for both strands are calculated)
# CPU_PER_JOB=10
# MEM_PER_JOB="40G"
# TIME_PER_JOB="25:00:00"

#      slurmArrayLauncher \
#       --command-name "prbRun_nHUSH"    \
#       --command-args "--work-dir ${WORKDIR} --cpu-per-job ${CPU_PER_JOB} --length-oligos ${OLIGO_LENGTH}" \
#       --cpu-per-job "${CPU_PER_JOB}" \
#       --mem-per-job "${MEM_PER_JOB}" \
#       --time-req "${TIME_PER_JOB}" \
#       --work-dir ${WORKDIR}


## output genes that run out of time during nHUSH step
# for file in ${WORKDIR}/logs/*/*nHUSH*.txt
#     echo ${file}
#     grep -l "DUE TO TIME LIMIT \*\*\*" ${file} | xargs -I {} sed -n '5p' {} > ${WORKDIR}/failed_directories.txt
# done    

# while read -r line; do
#     # Extract the directory path within the quotes
#     directory=$(echo "$line" | sed -n 's/.*"\(.*\)".*/\1/p')
#     echo "$directory"
#     #visualise number of transcripts per gene
#     wc -l "$directory/data/rois/all_regions_tsv"
# done <  ${WORKDIR}/directories.txt


### <------------------------------ Stall main.sh as long as prbRun_nHUSH jobs are running
slurmBlocker --job-name "prbRun_nHUSH" -s 60
### <------------------------------ Resume main.sh when prbRun_nHUSH jobs are finished



### prbRun_cQuery

# CPU_PER_JOB=10
# MEM_PER_JOB="30G"
# TIME_PER_JOB="15:00:00"

#     slurmArrayLauncher \
#      --command-name "prbRun_cQuery" \
#      --command-args "--work-dir ${WORKDIR} --cpu-per-job ${CPU_PER_JOB} --length-oligos ${OLIGO_LENGTH}" \
#      --cpu-per-job "${CPU_PER_JOB}" \
#      --mem-per-job "${MEM_PER_JOB}" \
#      --time-req "${TIME_PER_JOB}" \
#      --work-dir ${WORKDIR}


