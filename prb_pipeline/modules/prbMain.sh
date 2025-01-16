#!/bin/bash


### -----------------------------------------------------------------------------------
### -----------------------------------------------------------------------------------
### -----------------------------------------------------------------------------------


### 1. Importing Pipeline Modules
echo -e "Importing Pipeline Modules:"
for MOD in $(find "${PIPELINE_MODS}" -name "*.sh" ! -name "prbMain.sh"); do source "${MOD}"; done
echo -e "\nSingularity Image:\n${CONTAINER}\n"
### ----------------------------------------------------------------------------------
  
### 2. Input Pre-Processing ----------------------------------------------------------------
### ----------------------------------------------------------------------------------
### --- [prbReadInputGTF] Extracting input objects from provided GTF file
### --- [prbReadInputFasta] Extracting input objects from provided FASTA file
### --- [prbReadInputBed] Extracting input objects from provided BED file


if [[ ${INPUT_GTF} != "" ]]; then 

 prbReadInputGTF         \
  -i ${INPUT_GTF}        \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}   \
  -X ${CONTAINER}        \
  --ccds-only 

fi 


if [[ ${INPUT_FASTA} != "" ]]; then

 prbReadInputFasta       \
  -i ${INPUT_FASTA}      \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}   \
  -X ${CONTAINER}      

fi


if [[ ${INPUT_BED} != "" ]]; then

 prbReadInputBed         \
  -i ${INPUT_BED}        \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}   \
  -X ${CONTAINER}

fi



### ----------------------------------------------------------------------------------
### 3. Adding References -------------------------------------------------------------
### ----------------------------------------------------------------------------------

### Creating genome and blacklist reference and temporary objects.
### Finally, link all reference objects to each sub-directory

prbReferenceCreate -w ${WORKDIR} -g ${GENOME} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH} -X ${CONTAINER}



### ----------------------------------------------------------------------------------
### 4. Launching Pipeline ------------------------------------------------------------
### ----------------------------------------------------------------------------------




### Launching prbRun_nHUSH
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="05:00:00"

slurmArrayLauncher \
 --command-name "prbRun_nHUSH"    \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH} -X ${CONTAINER}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 20 \
 --slurm-array-max 900 \
 --slurm-hpc-max 950

### Waiting for prbRun_nHUSH jobs to finish
slurmBlocker --job-name "prbRun_nHUSH" -s 60



### Launching prbRun_cQuery
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="06:00:00"

slurmArrayLauncher \
 --command-name "prbRun_cQuery" \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH} -X ${CONTAINER}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 20 \
 --slurm-array-max 935 \
 --slurm-hpc-max 950




### Waiting for prbRun_nHUSH jobs to finish
slurmBlocker --job-name "prbRun_cQuery" -s 60

### Removing temporary files and directories
prbTmpClear -w ${WORKDIR}
echo -e "Process completed, exiting prbMain!\n$(date)"



