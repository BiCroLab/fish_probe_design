#!/bin/bash

#SBATCH --job-name=prb_main --partition=cpuq --time=99:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --mem=4G


### Importing Pipeline Modules
#modules connected to https://github.com/salvzzz/prb_parallel/tree/main
PIPELINE_MODS="/group/bienko/projects/RNAFISH/Scripts_PRB_git/prb_parallel/pipeline_transcriptid/modules"

echo -e "Importing Pipeline Modules:" && for MOD in ${PIPELINE_MODS}/*.sh; do source ${MOD}; done

### ----------------------------------------------------------------------------------
### Input Objects: 

GENOME="/group/bienko/annotations/human/hg38_GRCh38_p13/genome/Homo_sapiens.GRCh38.103.fa.gz"
INPUT_GTF="/group/bienko/annotations/human/hg38_GRCh38_p13/annotations/gencode/v43/gencode.v43.primary_assembly.basic.annotation.gtf.gz" 
WORKDIR="/group/bienko/projects/RNAFISH/test_tmp/"

OLIGO_LENGTH=40
OLIGO_SUBLENGTH=21


INPUT_FASTA=""
INPUT_BED=""
### ---------------------------------





### ----------------------------------------------------------------------------------
### 1. Pre-Processing ----------------------------------------------------------------
### ----------------------------------------------------------------------------------

### --- [prbReadInputGTF] Extracting input objects from provided GTF file
### --- [prbReadInputFasta] Extracting input objects from provided FASTA file
### --- [prbReadInputBed] Extracting input objects from provided BED file

prbReadInputGTF -i ${INPUT_GTF} -g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH} --ccds-only

# prbReadInputFasta -i ${INPUT_FASTA} -g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH}

# prbReadInputBed -i ${INPUT_BED} -g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH}


### ----------------------------------------------------------------------------------
### 2. Adding References -------------------------------------------------------------
### ----------------------------------------------------------------------------------

### Creating genome and blacklist reference and temporary objects.
### Finally, link all reference objects to each sub-directory

prbReferenceCreate -w ${WORKDIR} -g ${GENOME} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}



### TODO??? prbInputCheck -w ${WORKDIR}


### ----------------------------------------------------------------------------------
### 3. Launching Pipeline ------------------------------------------------------------
### ----------------------------------------------------------------------------------




### Launching prbRun_nHUSH
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="10:00:00"

slurmArrayLauncher \
 --command-name "prbRun_nHUSH"    \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 20 \
 --slurm-array-max 800 \
 --slurm-hpc-max 950



### Waiting for prbRun_nHUSH jobs to finish
slurmBlocker --job-name "prbRun_nHUSH" -s 60


### Launching prbRun_cQuery
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="24:00:00"

slurmArrayLauncher \
 --command-name "prbRun_cQuery" \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 10 \
 --slurm-array-max 800 \
 --slurm-hpc-max 950


