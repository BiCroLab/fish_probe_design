#!/bin/bash


### Importing Pipeline Modules
#PIPELINE_MODS="/group/bienko/projects/RNAFISH/Scripts_GeneID/modules"
PIPELINE_MODS="/scratch/raquel.andre/PROBES/Pipeline_LS_20241029/modules"

echo -e "Importing Pipeline Modules:" && for MOD in ${PIPELINE_MODS}/*.sh; do source ${MOD}; done

#define gene list of interest
#RANDOM_LIST="/group/bienko/projects/RNAFISH/Scripts/pipeline/modules/random.list.txt" 
GENE_LIST="/scratch/raquel.andre/PROBES/Pipeline_LS_20241029/modules/ENSGgenelistFunkGen.txt" 

#define directories
GENOME="/group/bienko/annotations/human/hg38_GRCh38_p13/genome/Homo_sapiens.GRCh38.103.fa.gz"
ANNOT_INPUT="/group/bienko/annotations/human/hg38_GRCh38_p13/annotations/gencode/v43/gencode.v43.primary_assembly.basic.annotation.gtf.gz" 
#WORKDIR="/group/bienko/projects/RNAFISH/Analysis_RNAmode6/Genes"
WORKDIR="/scratch/raquel.andre/PROBES/Pipeline_LS_20241029/"

### ----------------------------------------------------------------------------------
### ----------------------------------------------------------------------------------
### ----------------------------------------------------------------------------------
### METHOD #1: using parallel to speed up initial steps 
# fun() {
#     ID=${1}; GENOME=${2}; ANNOT_INPUT=${3}; WORKDIR=${4}


#     prbDesign001 -i ${ID} -g ${GENOME} -a ${ANNOT_INPUT} -w ${WORKDIR}
#     prbDesign002 -i ${ID} -g ${GENOME} -l 40 -w ${WORKDIR} -f "chr1"
#       }

# export -f fun
# CPU=8
# time parallel -j ${CPU} fun ::: $(cat ${RANDOM_LIST}) ::: ${GENOME} ::: ${ANNOT_INPUT} ::: ${WORKDIR}


# ### METHOD #2: using while-loops, slower for large numbers
# time while IFS= read -r ID; do
#     prbDesign001 -i ${ID} -g ${GENOME} -a ${ANNOT_INPUT} -w ${WORKDIR}
#     prbDesign002 -i ${ID} -g ${GENOME} -l 40 -w ${WORKDIR} -f "chr1"
# done < ${GENE_LIST}
# ### ----------------------------------------------------------------------------------
# ### ----------------------------------------------------------------------------------
# ### ----------------------------------------------------------------------------------

# #needs to be run only once per input genome to create a blacklisted region >> to be optimised since if loop is not working as expected

#     prbInitLinks -w ${WORKDIR} -g ${GENOME} -l 40 #--link-only


# ##step nHUSH (mers for both strands are calculated)
# CPU_PER_JOB=10

#     slurmArrayLauncher                      \
#      --command-name "prbRun_nHUSH"    \
#      --cpu-per-job "$CPU_PER_JOB"                \
#      --mem-per-job "35G"               \
#      --time-req "15:00:00"             \
#      --work-dir ${WORKDIR}              \
#      --command-args "--work-dir ${WORKDIR} --cpu-per-job ${CPU_PER_JOB}"    


##WAIT until all previous jobs have run >> add dependency ?

##step cQuery
CPU_PER_JOB=10

    slurmArrayLauncher                      \
     --command-name "prbRun_cQuery"    \
     --cpu-per-job "$CPU_PER_JOB"                 \
     --mem-per-job "30G"               \
     --time-req "15:00:00"             \
     --work-dir ${WORKDIR}              \
     --command-args "--work-dir ${WORKDIR} --cpu-per-job ${CPU_PER_JOB}" 

